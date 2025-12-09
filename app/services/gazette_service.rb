# frozen_string_literal: true

# Service for handling gazette list display with optimized database queries
# Replaces memory-intensive Ruby-based grouping and sorting with efficient
# PostgreSQL aggregations and pagination
#
# Usage:
#   result = GazetteService.call(params)
#   @gazettes_pagination = result[:gazettes]
#   @missing_gazettes = result[:missing_gazettes]
#   @sliced_count = result[:sliced_count]
class GazetteService
  # Class method for convenient calling following Rails service pattern
  # @param params [Hash] Request parameters (query, page)
  # @return [Hash] Result containing gazettes and metadata
  def self.call(params)
    new(params).call
  end

  # Initialize the service with request parameters
  # @param params [Hash] Request parameters
  #   - query: Search query for specific gazette number
  #   - page: Current page number for pagination
  def initialize(params)
    @params = params
  end

  def call
    {
      gazettes: gazettes,
      missing_gazettes: missing_gazettes,
      sliced_count: sliced_count,
      total_count: total_count
    }
  end

  private

  # Base query scope for documents with publication numbers
  # Applies search filter if query parameter is present
  # @return [ActiveRecord::Relation] Scoped document query
  def query_scope
    @query_scope ||= begin
      scope = Document.where.not(publication_number: nil)
      
      if @params[:query].present?
        query_str = @params[:query]
        # Handle 5-digit numbers without comma (e.g., "33555" -> "33,555")
        if query_str.length == 5 && query_str[1] != ','
          query_str = query_str.dup.insert(2, ",")
        end
        scope = scope.where(publication_number: query_str)
      end
      scope
    end
  end

  # Fetch paginated gazettes with aggregated metadata
  # Uses database-level GROUP BY to aggregate documents by publication_number
  # PERF: Aggregates at database level instead of loading all documents into memory
  # @return [ActiveRecord::Relation] Paginated gazette records with virtual attributes
  def gazettes
    @gazettes ||= begin
      query_scope
        .select(
          "publication_number",
          "MAX(publication_date) as date",
          # BOOL_OR returns true if ANY document in the group matches the condition
          "BOOL_OR(name = 'Gaceta') as has_original",
          "BOOL_OR(name != 'Gaceta') as is_sliced"
        )
        .group(:publication_number)
        # Complex sort: numeric gazettes first (descending), then alphanumeric
        # Uses regex to identify numeric-only publication numbers
        # PERF: CASE WHEN prevents CAST errors on non-numeric values like "Acuerdo No. CN-006-2018"
        .order(Arel.sql(
          "CASE WHEN publication_number ~ '^[0-9,]+$' THEN " \
          "CAST(REPLACE(publication_number, ',', '') AS INTEGER) END DESC NULLS LAST, " \
          "publication_number DESC"
        ))
        .page(@params[:page]).per(20)
    end
  end

  # Calculate missing gazette numbers (gaps in the sequence)
  # Only processes numeric publication numbers where gap detection makes sense
  # @return [Array<Integer>] Array of missing gazette numbers
  def missing_gazettes
    # Get ALL numeric publication numbers for gap detection
    # Note: This includes all pages, not just current page, to accurately detect gaps
    all_numbers = query_scope
      .where("publication_number ~ '^[0-9,]+$'") # Only numeric gazettes
      .select("DISTINCT publication_number")
      .order(Arel.sql("CAST(REPLACE(publication_number, ',', '') AS INTEGER) DESC"))
      .pluck(:publication_number)
      .map { |num| num.delete(',').to_i }
    
    missing = []
    # each_cons(2) iterates pairs: [33555, 33553], [33553, 33551], etc.
    all_numbers.each_cons(2) do |curr, next_val|
      # List is descending: [33555, 33553, ...]
      # If difference > 1, there are gaps (e.g., 33555 -> 33553 means 33554 is missing)
      if curr - 1 != next_val
        ((next_val + 1)...curr).each { |n| missing << n }
      end
    end
    missing
  end

  # Count of gazettes that have been "sliced" 
  # PERF: Uses database COUNT with DISTINCT instead of loading and iterating objects
  # @return [Integer] Count of sliced gazettes
  def sliced_count
    # Cache the count to avoid re-running on every access
    @sliced_count ||= begin
      # Count distinct publication_numbers where at least one document is not 'Gaceta'
      # This identifies gazettes that have been broken into separate document entries
      query_scope
        .select(:publication_number)
        .where.not(name: 'Gaceta')
        .distinct
        .count
    end
  end
  
  # Total count of unique gazettes across all pages
  # Uses Kaminari's total_count for efficient counting with pagination
  # @return [Integer] Total gazette count
  def total_count
    # Leverages Kaminari's cached count from the paginated relation
    # PERF: Kaminari caches the count query result to avoid redundant COUNT(*)
    gazettes.total_count
  end
end
