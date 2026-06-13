# frozen_string_literal: true

module Search
  # Serializes a pre-grouped law→articles entry from ResultGrouper.
  # Builds law metadata from the first article's denormalized ES fields.
  #
  # Input:  { type: :law_group, law_id: 15, articles: [[source, highlights], ...] }
  # Output: { _type: "law_group", law: { id, name, ... }, articles: [{ id, number, body, snippet }] }
  class GroupedLawSerializer
    def initialize(law_group)
      @articles = law_group[:articles] # [[source, highlights], ...]
      @first_source = @articles.first&.first
    end

    def serialize
      {
        _type: 'law_group',
        law: serialize_law,
        articles: @articles.map { |source, highlights| serialize_article(source, highlights) }
      }
    end

    private

    def serialize_law
      {
        id: @first_source.law_id,
        name: @first_source.law_name,
        creation_number: @first_source.law_creation_number,
        status: @first_source.law_status,
        hierarchy: @first_source.law_hierarchy,
        url: "#{Rails.configuration.x.todolegal_base_url}/laws/#{@first_source.law_id}-#{@first_source.law_name.to_s.parameterize}",
        tags: @first_source.law_tag_names || []
      }
    end

    def serialize_article(source, highlights)
      hl = (highlights || {}).transform_keys(&:to_sym)
      {
        _score: source._score,
        id: source.id,
        number: source.number&.strip,
        body: source.body&.truncate(500),
        snippet: hl[:body] || source.body&.truncate(200),
        highlights: hl
      }
    end
  end
end
