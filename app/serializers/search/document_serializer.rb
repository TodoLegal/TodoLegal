# frozen_string_literal: true

module Search
  class DocumentSerializer < BaseSerializer
    # @param source [Searchkick::HashWrapper] ES _source data
    # @param highlights [Hash] highlight fragments
    # @param file_url [String, nil] pre-resolved ActiveStorage URL (injected by controller)
    def initialize(source, highlights: {}, file_url: nil)
      super(source, highlights: highlights)
      @file_url = file_url
    end

    def serialize
      data = {
        _type: 'document',
        _score: source._score,
        id: source.id,
        issue_id: source.issue_id,
        name: source.name,
        description: source.description,
        publication_date: source.publication_date,
        publication_number: source.publication_number,
        document_type: source.document_type_name,
        issuer: Array(source.issuer_document_tags_name).first,
        tags: build_tags,
        url: build_url,
        highlights: highlights
      }

      # Only expose file URL for users with document access (pro plan / active trial).
      # The URL is batch-loaded by the controller before serialization.
      data[:file_url] = @file_url if @file_url

      data
    end

    private

    # Reads structured tag data from ES _source (indexed as document_tags_data).
    # Falls back to flat document_tags_name if structured data is not present.
    def build_tags
      structured = source.respond_to?(:document_tags_data) && source.document_tags_data
      if structured.is_a?(Array) && structured.any?
        structured.map { |t| { name: t['name'] || t[:name], type: t['type'] || t[:type] || '' } }
      else
        Array(source.document_tags_name).map { |name| { name: name, type: '' } }
      end
    end

    # Builds the full Valid frontend URL for this document.
    # Pattern: {VALID_BASE_URL}/{documentTypeSlug}/honduras/{urlSlug}/{id}
    def build_url
      base = Rails.configuration.x.valid_base_url
      type_slug = slugify(source.document_type_name.presence || 'gaceta')
      url_slug = build_url_slug
      "#{base}/#{type_slug}/honduras/#{url_slug}/#{source.id}"
    end

    def build_url_slug
      if source.name.present?
        slugify(source.name)
      elsif source.issue_id.present?
        slugify(source.issue_id.to_s)
      else
        'gaceta'
      end
    end

    # Replicates the JS slug logic: remove accents, replace slashes/spaces/dots with hyphens, lowercase.
    def slugify(text)
      I18n.transliterate(text)
        .gsub(%r{[/,.]}, '-')
        .gsub(/\s+/, '-')
        .downcase
        .gsub(/-{2,}/, '-')
        .gsub(/\A-|-\z/, '')
    end
  end
end
