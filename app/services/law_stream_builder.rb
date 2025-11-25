# frozen_string_literal: true

# Builder class for constructing law display streams
# Handles the complex logic of interleaving books, titles, chapters, 
# sections, subsections, and articles in correct order
class LawStreamBuilder
  # Initialize builder with law and components
  # @param law [Law] The law object
  # @param components [Hash] Hash containing all law components
  # @param go_to_position [Integer, nil] Position to scroll to
  def initialize(law:, components:, go_to_position: nil)
    @law = law
    @components = components
    @go_to_position = go_to_position
    
    # Extract components for easier access
    @books = components[:books]
    @titles = components[:titles]
    @chapters = components[:chapters]
    @sections = components[:sections]
    @subsections = components[:subsections]
    @articles = components[:articles]
  end

  # Build the interleaved stream of law components
  # @return [Hash] Result hash with stream, index_items, go_to_article, has_articles_only
  def build
    initialize_counters
    initialize_result_arrays
    
    stream_size = calculate_total_stream_size
    
    # Build the interleaved stream
    (0...stream_size).each do |i|
      add_next_component_to_stream
    end
    
    # Determine if stream contains only articles
    has_articles_only = only_articles_in_stream?
    
    {
      stream: @result_stream,
      index_items: @result_index_items,
      go_to_article: @result_go_to_article,
      has_articles_only: has_articles_only
    }
  end

  private

  # Initialize counters for each component type
  def initialize_counters
    @book_iterator = 0
    @title_iterator = 0
    @chapter_iterator = 0
    @section_iterator = 0
    @subsection_iterator = 0
    @article_iterator = 0
  end

  # Initialize result arrays
  def initialize_result_arrays
    @result_stream = []
    @result_index_items = []
    @result_go_to_article = nil
  end

  # Calculate total number of items in the stream
  # @return [Integer] Total stream size
  def calculate_total_stream_size
    @books.size +
    @titles.size +
    @chapters.size +
    @sections.size +
    @subsections.size +
    @articles.size
  end

  # Add the next component to the stream based on position ordering
  def add_next_component_to_stream
    if should_add_book?
      add_book_to_stream
    elsif should_add_title?
      add_title_to_stream
    elsif should_add_chapter?
      add_chapter_to_stream
    elsif should_add_section?
      add_section_to_stream
    elsif should_add_subsection?
      add_subsection_to_stream
    else
      add_article_to_stream
    end
  end

  # Check if book should be added next (based on position comparison)
  # @return [Boolean] True if book should be added
  def should_add_book?
    return false unless @book_iterator < @books.size
    
    current_book = @books[@book_iterator]
    return false unless current_book
    
    # Check if book position is less than all other component positions
    book_position = current_book.position
    
    (@titles.size == 0 || position_less_than?(:title, book_position)) &&
    (@chapters.size == 0 || position_less_than?(:chapter, book_position)) &&
    (@sections.size == 0 || position_less_than?(:section, book_position)) &&
    (@subsections.size == 0 || position_less_than?(:subsection, book_position)) &&
    (@articles.size == 0 || position_less_than?(:article, book_position))
  end

  # Check if title should be added next
  # @return [Boolean] True if title should be added
  def should_add_title?
    return false unless @title_iterator < @titles.size
    
    current_title = @titles[@title_iterator]
    return false unless current_title
    
    title_position = current_title.position
    
    (@chapters.size == 0 || position_less_than?(:chapter, title_position)) &&
    (@sections.size == 0 || position_less_than?(:section, title_position)) &&
    (@subsections.size == 0 || position_less_than?(:subsection, title_position)) &&
    (@articles.size == 0 || position_less_than?(:article, title_position))
  end

  # Check if chapter should be added next
  # @return [Boolean] True if chapter should be added
  def should_add_chapter?
    return false unless @chapter_iterator < @chapters.size
    
    current_chapter = @chapters[@chapter_iterator]
    return false unless current_chapter
    
    chapter_position = current_chapter.position
    
    (@sections.size == 0 || position_less_than?(:section, chapter_position)) &&
    (@subsections.size == 0 || position_less_than?(:subsection, chapter_position)) &&
    (@articles.size == 0 || position_less_than?(:article, chapter_position))
  end

  # Check if section should be added next
  # @return [Boolean] True if section should be added
  def should_add_section?
    return false unless @section_iterator < @sections.size
    
    current_section = @sections[@section_iterator]
    return false unless current_section
    
    section_position = current_section.position
    
    (@subsections.size == 0 || position_less_than?(:subsection, section_position)) &&
    (@articles.size == 0 || position_less_than?(:article, section_position))
  end

  # Check if subsection should be added next
  # @return [Boolean] True if subsection should be added
  def should_add_subsection?
    return false unless @subsection_iterator < @subsections.size
    
    current_subsection = @subsections[@subsection_iterator]
    return false unless current_subsection
    
    subsection_position = current_subsection.position
    
    (@articles.size == 0 || position_less_than?(:article, subsection_position))
  end

  # Helper method to check if current component position is less than comparison position
  # @param component_type [Symbol] Type of component to compare (:title, :chapter, etc.)
  # @param comparison_position [Integer] Position to compare against
  # @return [Boolean] True if current component position is less
  def position_less_than?(component_type, comparison_position)
    case component_type
    when :title
      return true unless @title_iterator < @titles.size
      @titles[@title_iterator]&.position && @titles[@title_iterator].position > comparison_position
    when :chapter
      return true unless @chapter_iterator < @chapters.size
      @chapters[@chapter_iterator]&.position && @chapters[@chapter_iterator].position > comparison_position
    when :section
      return true unless @section_iterator < @sections.size
      @sections[@section_iterator]&.position && @sections[@section_iterator].position > comparison_position
    when :subsection
      return true unless @subsection_iterator < @subsections.size
      @subsections[@subsection_iterator]&.position && @subsections[@subsection_iterator].position > comparison_position
    when :article
      return true unless @article_iterator < @articles.size
      @articles[@article_iterator]&.position && @articles[@article_iterator].position > comparison_position
    end
  end

  # Add book to stream and increment counter
  def add_book_to_stream
    book = @books[@book_iterator]
    @result_stream << book
    @result_index_items << book
    @book_iterator += 1
  end

  # Add title to stream and increment counter
  def add_title_to_stream
    title = @titles[@title_iterator]
    @result_stream << title
    @result_index_items << title
    @title_iterator += 1
  end

  # Add chapter to stream and increment counter
  def add_chapter_to_stream
    chapter = @chapters[@chapter_iterator]
    @result_stream << chapter
    @result_index_items << chapter
    @chapter_iterator += 1
  end

  # Add section to stream and increment counter
  def add_section_to_stream
    section = @sections[@section_iterator]
    @result_stream << section
    @result_index_items << section
    @section_iterator += 1
  end

  # Add subsection to stream and increment counter
  def add_subsection_to_stream
    subsection = @subsections[@subsection_iterator]
    @result_stream << subsection
    @result_index_items << subsection
    @subsection_iterator += 1
  end

  # Add article to stream and check for go_to_position
  def add_article_to_stream
    article = @articles[@article_iterator]
    @result_stream << article
    
    # Check if this is the target article for go_to_position
    if @go_to_position && article&.position == @go_to_position
      @result_go_to_article = @article_iterator
    end
    
    @article_iterator += 1
  end

  # Check if stream contains only articles (no other structural components)
  # @return [Boolean] True if only articles were added to stream
  def only_articles_in_stream?
    @book_iterator == 0 &&
    @title_iterator == 0 &&
    @chapter_iterator == 0 &&
    @section_iterator == 0 &&
    @subsection_iterator == 0
  end
end