# frozen_string_literal: true

module Search
  class ArticleSerializer < BaseSerializer
    def serialize
      {
        _type: 'article',
        _score: source._score,
        id: source.id,
        article_number: source.number&.strip,
        law_id: source.law_id,
        law_name: source.law_name,
        law_url: "#{Rails.configuration.x.todolegal_base_url}/leyes/#{source.law_id}-#{source.law_name.to_s.parameterize}",
        law_hierarchy: source.law_hierarchy,
        body: source.body,
        highlights: highlights
      }
    end
  end
end
