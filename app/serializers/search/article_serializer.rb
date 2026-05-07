# frozen_string_literal: true

module Search
  class ArticleSerializer < BaseSerializer
    def serialize
      {
        _type: 'article',
        id: source.id,
        article_number: source.number&.strip,
        law_id: source.law_id,
        law_name: source.law_name,
        body_snippet: body_snippet,
        highlights: highlights
      }
    end

    private

    # Use the highlighted body if available, otherwise truncate the ES body
    # (already sanitized in Article#search_data — HTML + markdown stripped).
    def body_snippet
      return highlights[:body] if highlights[:body].present?

      source.body&.truncate(200)
    end
  end
end
