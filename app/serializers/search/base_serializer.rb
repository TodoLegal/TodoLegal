# frozen_string_literal: true

module Search
  # Base class for search result serializers.
  # Accepts ES _source data (Searchkick::HashWrapper from load: false) instead of AR records,
  # so results are served directly from Elasticsearch without DB round-trips.
  class BaseSerializer
    attr_reader :source, :highlights

    # @param source [Searchkick::HashWrapper] ES _source hash (from load: false)
    # @param highlights [Hash] highlight fragments from Searchkick's with_highlights
    def initialize(source, highlights: {})
      @source = source
      @highlights = (highlights || {}).transform_keys(&:to_sym)
    end

    # Subclasses must implement this
    def serialize
      raise NotImplementedError, "#{self.class} must implement #serialize"
    end

    # Factory: picks the right serializer based on the ES _index name.
    def self.for(source, highlights: {})
      index = source._index.to_s
      case index
      when /\Aarticles_/   then ArticleSerializer.new(source, highlights: highlights)
      when /\Adocuments_/  then DocumentSerializer.new(source, highlights: highlights)
      else raise ArgumentError, "No serializer for index #{index}"
      end
    end
  end
end
