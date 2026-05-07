# frozen_string_literal: true

module Search
  # Single entry point for searching across all legal content (laws, articles, gazette documents).
  # Replaces three separate search paths (DocumentsController/Searchkick, HomeController/pg_search,
  # LawsController/pg_search) with one Elasticsearch query via Searchkick.
  #
  #   result = Search::UnifiedSearchService.call(query: "constitución", type: "law", filters: { status: "vigente" })
  #   result.success?        # => true
  #   result.data[:results]  # => [#<Law ...>, ...]
  #   result.data[:facets]   # => { content_type: { law: 3, article: 12, document: 0 }, ... }
  class UnifiedSearchService < ApplicationService
    MODELS = [Law, Article, Document].freeze

    MODEL_MAP = {
      'law' => Law,
      'article' => Article,
      'document' => Document
    }.freeze

    DEFAULT_PER_PAGE = 20
    MAX_PER_PAGE = 100

    # Field boosts for multi-model search. ES ignores fields that don't exist on a given
    # model's index, so all fields can be listed together without conflict.
    # Boost values set relative ranking priority within and across models.
    SEARCH_FIELDS = [
      # Law fields
      "name^10",
      "creation_number^8",
      "tag_names^3",
      "materia_names^3",
      "hierarchy^2",
      "status^1",
      # Article fields
      "body^5",
      "number^3",
      "law_name^2",
      "law_tag_names^1",
      # Document fields (name^10 shared with Law)
      "issue_id^8",
      "short_description^6",
      "description^4",
      "issuer_document_tags_name^3",
      "document_type_name^2",
      "document_type_alternative_name^2",
      "publication_number^2",
      "publication_date^1",
      "publication_date_dashes^1",
      "publication_date_slashes^1",
      "document_tags_name^1"
    ].freeze

    HIGHLIGHT_FIELDS = %i[name body description short_description].freeze

    def initialize(query:, type: nil, filters: {}, page: 1, per_page: DEFAULT_PER_PAGE)
      @query = query.presence || '*'
      @type = type
      @filters = (filters || {}).symbolize_keys
      @page = [page.to_i, 1].max
      @per_page = (per_page.presence || DEFAULT_PER_PAGE).to_i.clamp(1, MAX_PER_PAGE)
    end

    def call
      results = execute_search

      aggs = begin
               results.aggs
             rescue Searchkick::Error
               {}
             end

      content_type_facet = build_content_type_facet(aggs)

      # with_highlights returns an Enumerator of [record, highlights_hash] pairs.
      # With load: false, records are Searchkick::HashWrapper (ES _source).
      # Convert to Array so it can be iterated multiple times by the controller.
      results_with_highlights = results.with_highlights.to_a

      success({
        results_with_highlights: results_with_highlights,
        total: results.total_count,
        page: @page,
        per_page: @per_page,
        total_pages: (results.total_count.to_f / @per_page).ceil,
        facets: {
          content_type: content_type_facet,
          status: parse_agg_buckets(aggs['status']),
          tags: parse_agg_buckets(aggs['tag_names'])
        },
        metadata: {
          laws_count: content_type_facet[:law],
          articles_count: content_type_facet[:article],
          documents_count: content_type_facet[:document]
        }
      })
    rescue Searchkick::Error, Elastic::Transport::Transport::Error => e
      failure("Search unavailable: #{e.message}")
    end

    private

    def execute_search
      query = prepare_query

      options = {
        models: target_models,
        fields: SEARCH_FIELDS,
        where: build_where,
        page: @page,
        per_page: @per_page,
        # Read results directly from ES _source — no DB round-trip.
        # Serializers work with Searchkick::HashWrapper instead of AR records.
        load: false,
        misspellings: { edit_distance: 2, below: 2 },
        highlight: { fields: HIGHLIGHT_FIELDS, tag: '<mark>', fragment_size: 200 },
        aggs: { status: {}, tag_names: { limit: 20 } },
        # Raw ES aggregation on _index to get accurate per-type totals across all
        # matching documents (not just the current page). Searchkick's `aggs` option
        # doesn't support _index natively, so we inject it via body_options.
        body_options: {
          aggs: {
            content_type: { terms: { field: '_index', size: 10 } }
          }
        }
      }

      # For wildcard queries, order by score (default relevance)
      options[:order] = { _score: :desc } if query == '*'

      Searchkick.search(query, **options)
    end

    # If the query looks like a Spanish date and no explicit date range filters are set,
    # convert it to ISO format so ES matches the indexed date fields.
    def prepare_query
      return @query if @query == '*'
      return @query if @filters[:from].present? || @filters[:to].present?

      date_result = Search::DateParser.parse(@query)
      date_result ? date_result[:date] : @query
    end

    def target_models
      return MODELS unless @type.present?

      model = MODEL_MAP[@type.to_s.downcase]
      model ? [model] : MODELS
    end

    def build_where
      where = {}

      where[:status] = @filters[:status] if @filters[:status].present?

      if @filters[:from].present? || @filters[:to].present?
        date_range = {}
        date_range[:gte] = @filters[:from] if @filters[:from].present?
        date_range[:lte] = @filters[:to] if @filters[:to].present?
        where[:publication_date] = date_range
      end

      # Tags are stored under different field names per model (tag_names for Laws,
      # law_tag_names for Articles, document_tags_name for Documents). _or matches
      # across all of them so a single tag filter works regardless of content type.
      if @filters[:tags].present?
        tag_list = Array(@filters[:tags])
        where[:_or] = [
          { tag_names: tag_list },
          { materia_names: tag_list },
          { law_tag_names: tag_list },
          { document_tags_name: tag_list }
        ]
      end

      # Exclude unpublished documents in all search modes.
      # Laws/Articles don't index a publish field, so they never match publish: false.
      where[:_not] = { publish: false }

      where
    end

    def build_content_type_facet(aggs)
      counts = { law: 0, article: 0, document: 0 }
      buckets = aggs.dig('content_type', 'buckets') || []

      buckets.each do |bucket|
        model_key = index_name_to_type(bucket['key'])
        counts[model_key] += bucket['doc_count'] if model_key
      end

      counts
    end

    # Maps Searchkick index names (e.g. "laws_test_20260505034429503") back to
    # model type symbols for the content_type facet.
    def index_name_to_type(index_name)
      case index_name
      when /\Alaws_/     then :law
      when /\Aarticles_/  then :article
      when /\Adocuments_/ then :document
      end
    end

    def parse_agg_buckets(agg)
      return {} unless agg && agg['buckets']

      agg['buckets'].each_with_object({}) do |bucket, hash|
        hash[bucket['key']] = bucket['doc_count']
      end
    end


  end
end
