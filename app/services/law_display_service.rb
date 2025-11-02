# frozen_string_literal: true

# Service for handling law display logic with chunked loading
# Replaces the memory-intensive get_raw_law controller method
# with a more efficient, testable, and maintainable approach
class LawDisplayService < ApplicationService
  include LawDisplayConfig

  # Initialize the service with required parameters
  # @param law [Law] The law to display
  # @param user [User, nil] Current user for access control
  # @param params [Hash] Request parameters (query, articles, etc.)
  def initialize(law, user: nil, params: {})
    @law = law
    @user = user
    @params = params.is_a?(ActionController::Parameters) ? params : params.with_indifferent_access
    @query = @params[:query]&.strip
    @articles_filter = @params[:articles]
    
    # Chunking parameters for progressive loading
    @page = [@params[:page]&.to_i || 1, 1].max # Ensure page is at least 1
    @chunk_size = determine_chunk_size
  end

  # Main service method - processes law display request
  # @return [ServiceResult] Result containing display data or errors
  def call
    return failure('Law is required') unless @law

    begin
      # Initialize base display state
      display_data = initialize_display_state

      # Process based on request type
      if search_request?
        process_search_request(display_data)
      elsif article_filter_request?
        process_article_filter_request(display_data)
      else
        process_normal_display_request(display_data)
      end

      # Apply access limitations for non-premium users
      apply_access_limitations(display_data)

      # Track search analytics if needed
      track_search_analytics(display_data) if @user && (search_request? || article_filter_request?)

      success(display_data, build_metadata(display_data))

    rescue => e
      Rails.logger.error "LawDisplayService error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      failure("Error processing law display: #{e.message}")
    end
  end

  private

  # Initialize the base display state
  # @return [Hash] Base display data structure
  def initialize_display_state
    {
      stream: [],
      highlight_enabled: false,
      query: @query || "",
      articles_count: 0,
      has_articles_only: true,
      info_is_searched: false,
      result_index_items: [],
      go_to_article: nil,
      user_can_edit_law: false, # Will be set by controller
      user_can_access_law: true # Will be modified based on user access
    }
  end

  # Check if this is a search request
  # @return [Boolean] True if query parameter present
  def search_request?
    @query.present? && @query.length >= SEARCH_CONFIG[:min_query_length]
  end

  # Check if this is an article filter request
  # @return [Boolean] True if articles parameter present
  def article_filter_request?
    @articles_filter.present?
  end

  # Check if this is a chunked request (page parameter provided)
  # @return [Boolean] True if requesting a specific page/chunk
  def chunked_request?
    @params[:page].present?
  end

  # Determine appropriate chunk size based on context
  # @return [Integer] Chunk size to use
  def determine_chunk_size
    context = search_request? ? :search : :normal
    chunk_size_for(user: @user, context: context)
  end

  # Process search request with highlighting
  # @param display_data [Hash] Display data to populate
  def process_search_request(display_data)
    # Parse query for article numbers if starts with '/'
    parsed_articles = parse_article_query(@query)
    
    if parsed_articles.any?
      # Convert query like "/123" to article filter
      @articles_filter = parsed_articles
      display_data[:query] = ""
      process_article_filter_request(display_data)
    else
      # Perform full-text search with chunking
      perform_search_with_chunking(display_data)
    end
  end

  # Parse query for article numbers (handles "/123" format)
  # @param query [String] Search query
  # @return [Array<String>] Array of article numbers
  def parse_article_query(query)
    return [] unless query&.start_with?('/')
    
    tokens = query.scan(/\w+|\W/)
    articles = []
    
    tokens.each do |token|
      articles << token if token.match?(/\A\d+\z/)
    end
    
    articles
  end

  # Perform full-text search with result chunking
  # @param display_data [Hash] Display data to populate
  def perform_search_with_chunking(display_data)
    # Use pg_search for highlighted results
    search_results = @law.articles
      .search_by_body_highlighted(@query)
      .with_pg_search_highlight
      .order(:position)
      .limit(SEARCH_CONFIG[:max_results]) #Analyze if I want to limit results when searching

    display_data[:highlight_enabled] = true
    display_data[:query] = @query
    display_data[:info_is_searched] = true
    display_data[:stream] = search_results.sort_by(&:position)
    display_data[:articles_count] = search_results.size
  end

  # Process article filter request (specific articles)
  # @param display_data [Hash] Display data to populate
  def process_article_filter_request(display_data)
    articles = @law.articles.order(:position)
    
    if @articles_filter.size == 1
      # Single article - find and position to it
      process_single_article_request(display_data, articles)
    else
      # Multiple articles - show only requested ones
      display_data[:stream] = articles.where(number: @articles_filter)
      display_data[:articles_count] = display_data[:stream].size
    end
  end

  # Process single article request with positioning
  # @param display_data [Hash] Display data to populate
  # @param articles [ActiveRecord::Relation] Articles relation
  def process_single_article_request(display_data, articles)
    target_article = articles.where('number LIKE ?', "%#{@articles_filter.first}%").first
    go_to_position = target_article&.position
    
    # Load full law stream and find position
    stream_result = build_law_stream(go_to_position)
    
    display_data[:stream] = stream_result[:stream]
    display_data[:result_index_items] = stream_result[:index_items]
    display_data[:go_to_article] = stream_result[:go_to_article]
    display_data[:has_articles_only] = stream_result[:has_articles_only]
    display_data[:articles_count] = @law.cached_articles_count
  end

  # Process normal law display (with progressive chunking)
  # @param display_data [Hash] Display data to populate
  def process_normal_display_request(display_data)
    # Build law stream with chunking support
    stream_result = build_chunked_law_stream
    
    display_data[:stream] = stream_result[:stream]
    display_data[:result_index_items] = stream_result[:index_items]
    display_data[:go_to_article] = stream_result[:go_to_article]
    display_data[:has_articles_only] = stream_result[:has_articles_only]
    display_data[:articles_count] = stream_result[:displayed_articles_count]
    display_data[:total_articles_count] = @law.cached_articles_count
    
    # Add chunk metadata if present (for chunked requests)
    display_data[:chunk_metadata] = stream_result[:chunk_metadata] if stream_result[:chunk_metadata]
  end

  # Build the law stream with all components (books, titles, chapters, etc.)
  # This is a more maintainable version of the original get_law_stream method
  # @param go_to_position [Integer, nil] Position to scroll to
  # @return [Hash] Stream data with components
  def build_law_stream(go_to_position = nil)
    # Load all law components - legacy method for backward compatibility
    components = load_law_components
    
    # Build the interleaved stream
    stream_builder = LawStreamBuilder.new(
      law: @law,
      components: components,
      go_to_position: go_to_position
    )
    
    stream_builder.build
  end

  # Build chunked law stream with progressive loading
  # @param go_to_position [Integer, nil] Position to scroll to
  # @return [Hash] Stream data with components and chunk metadata
  def build_chunked_law_stream(go_to_position = nil)
    # Load components with chunking support (mixed approach)
    components = load_chunked_law_components
    chunk_metadata = calculate_chunk_metadata(components[:articles])
    
    # Build the interleaved stream
    stream_builder = LawStreamBuilder.new(
      law: @law,
      components: components,
      go_to_position: go_to_position
    )
    
    result = stream_builder.build
    
    # Add chunk-specific metadata
    result.merge!(
      displayed_articles_count: components[:articles].size,
      chunk_metadata: chunk_metadata,
      current_page: @page,
      chunk_size: @chunk_size
    )
    
    result
  end

  # Load all law components (books, titles, chapters, etc.)
  # @return [Hash] Hash of component arrays
  def load_law_components
    {
      books: @law.books.order(:position),
      titles: @law.titles.order(:position),
      chapters: @law.chapters.order(:position),
      sections: @law.sections.order(:position),
      subsections: @law.subsections.order(:position),
      articles: @law.articles.order(:position)
    }
  end

  # Load law components with chunked articles (mixed approach)
  # Structure components (books, titles, etc.) are always loaded for navigation
  # Articles are loaded in chunks for performance
  # @return [Hash] Hash of component arrays with chunked articles
  def load_chunked_law_components
    # Load articles in chunks first to determine position range
    articles = load_chunked_articles
    
    if articles.any?
      # Filter structure components to only include those within the article range
      # This ensures proper interleaving without breaking the algorithm
      max_position = articles.last.position
      
      {
        books: @law.books.where('position <= ?', max_position).order(:position),
        titles: @law.titles.where('position <= ?', max_position).order(:position),
        chapters: @law.chapters.where('position <= ?', max_position).order(:position),
        sections: @law.sections.where('position <= ?', max_position).order(:position),
        subsections: @law.subsections.where('position <= ?', max_position).order(:position),
        articles: articles
      }
    else
      # No articles in chunk, return empty structure
      {
        books: @law.books.none,
        titles: @law.titles.none,
        chapters: @law.chapters.none,
        sections: @law.sections.none,
        subsections: @law.subsections.none,
        articles: articles
      }
    end
  end

  # Load articles for the current chunk/page
  # @return [ActiveRecord::Relation] Chunked articles
  def load_chunked_articles
    # Calculate offset based on page and chunk size
    offset = (@page - 1) * @chunk_size
    
    @law.articles
        .order(:position)
        .limit(@chunk_size)
        .offset(offset)
  end

  # Apply basic access limitations based on user type
  # Note: The controller handles law-specific access with user_can_access_law method
  # @param display_data [Hash] Display data to modify
  def apply_access_limitations(display_data)
    # For chunked requests, we handle access limitations differently
    # We show the requested chunk but mark access as limited for the controller to handle
    if @user.nil?
      # For chunked requests (page > 1), don't limit the stream here
      # Let the controller handle the access restriction
      if !chunked_request? && !search_request? && !article_filter_request?
        # Only apply basic limits for full law display on first page
        display_data[:stream] = display_data[:stream].take(ACCESS_LIMITS[:basic]) if display_data[:stream].respond_to?(:take)
      end
      display_data[:user_can_access_law] = false
    else
      display_data[:user_can_access_law] = true
    end
  end

  # Track search analytics
  # @param display_data [Hash] Display data for analytics
  def track_search_analytics(display_data)
    return unless defined?($tracker) && $tracker

    results = display_data[:stream]&.count || 0
    
    $tracker.track(@user.id, 'Site Search', {
      'query' => display_data[:query],
      'location' => @law.name,
      'location_type' => "Law",
      'results' => results
    })
  end

  # Calculate metadata for chunked loading
  # @param articles [ActiveRecord::Relation] Current chunk of articles
  # @return [Hash] Chunk metadata for pagination
  def calculate_chunk_metadata(articles)
    total_articles = @law.cached_articles_count
    total_pages = (total_articles.to_f / @chunk_size).ceil
    has_more = @page < total_pages
    
    {
      current_page: @page,
      total_pages: total_pages,
      chunk_size: @chunk_size,
      displayed_articles: articles.size,
      total_articles: total_articles,
      has_more_chunks: has_more,
      is_first_chunk: @page == 1,
      is_last_chunk: !has_more
    }
  end

  # Build metadata for the result
  # @param display_data [Hash] Display data
  # @return [Hash] Metadata hash
  def build_metadata(display_data)
    base_metadata = {
      law_id: @law.id,
      law_name: @law.name,
      total_articles: @law.cached_articles_count,
      displayed_articles: display_data[:articles_count] || display_data[:total_articles_count],
      is_search: display_data[:info_is_searched],
      has_query: display_data[:query].present?,
      user_type: @user ? 'authenticated' : 'anonymous',
      access_limited: !display_data[:user_can_access_law]
    }
    
    # Add chunk metadata if present
    if display_data[:chunk_metadata]
      base_metadata.merge!(display_data[:chunk_metadata])
    end
    
    base_metadata
  end

  private


end