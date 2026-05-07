# frozen_string_literal: true

module Search
  class LawSerializer < BaseSerializer
    def serialize
      {
        _type: 'law',
        id: source.id,
        name: source.name,
        creation_number: source.creation_number,
        status: source.status,
        url: "/leyes/#{source.id}-#{source.name.to_s.parameterize}",
        tags: source.tag_names || [],
        highlights: highlights
      }
    end
  end
end
