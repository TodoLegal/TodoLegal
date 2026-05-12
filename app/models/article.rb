class CustomRender < Redcarpet::Render::HTML
  def paragraph(text)
    text
  end
end

class Article < ApplicationRecord
  include PgSearch::Model
 searchkick language: 'spanish', callbacks: :async, merge_mappings: true, mappings: {
    properties: {
      law_creation_number: { type: 'keyword' }
    }
  }

  belongs_to :law, touch: true
  has_many :law_hyperlinks, dependent: :destroy

  scope :search_import, -> { includes(:law, law: :tags) }

  pg_search_scope :search_by_body_highlighted,
                  against: :body,
                  ignoring: :accents,
                  using: {
                    tsearch: {
                      dictionary: "tl_config",
                      tsvector_column: 'body_tsv',
                      highlight: {
                        StartSel: '<b style="color: var(--c-highlight); background-color: var(--c-highlight-background)" class="highlighted">',
                        StopSel: '</b>',
                        MaxWords: 9999,
                        MinWords: 456,
                        ShortWord: 0,
                        HighlightAll: true,
                        MaxFragments: 3,
                        FragmentDelimiter: '&hellip;'
                      }
                    }
                  }

  pg_search_scope :search_by_body_trimmed,
                  against: :body,
                  ignoring: :accents,
                  using: {
                    tsearch: {
                      dictionary: "tl_config",
                      tsvector_column: 'body_tsv',
                      highlight: {
                        StartSel: '<b>',
                        StopSel: '</b>',
                        MaxWords: 20,
                        MinWords: 60,
                        ShortWord: 1,
                        HighlightAll: true,
                        MaxFragments: 3,
                        FragmentDelimiter: '&hellip;'
                      }
                    }
                  }

  pg_search_scope :search_by_body_highlighted_and_trimmed,
                  against: :body,
                  ignoring: :accents,
                  using: {
                    tsearch: {
                      dictionary: "tl_config",
                      tsvector_column: 'body_tsv',
                      highlight: {
                        StartSel: '<b style="color: var(--c-highlight); background-color: var(--c-highlight-background)" class="highlighted">',
                        StopSel: '</b>',
                        MaxWords: 20,
                        MinWords: 456,
                        ShortWord: 0,
                        HighlightAll: true,
                        MaxFragments: 3,
                        FragmentDelimiter: '&hellip;'
                      }
                    }
                  }

  pg_search_scope :roughly_spelled_like,
                  against: :body,
                  using: {
                    tsearch: {
                      tsvector_column: 'body_tsv',
                      highlight: {
                        StartSel: '<b style="color: var(--c-highlight)">',
                        StopSel: '</b>',
                        MaxWords: 123,
                        MinWords: 456,
                        ShortWord: 4,
                        HighlightAll: true,
                        MaxFragments: 3,
                        FragmentDelimiter: '&hellip;'
                      }
                    }
                  }

  class << self
    def markdown
      @markdown ||= Redcarpet::Markdown.new(CustomRender, tables: true)
    end
  end

  def search_data
    sanitized = ActionView::Base.full_sanitizer.sanitize(body)
    # Strip markdown syntax (bold, italic, headers) that full_sanitizer doesn't handle
    sanitized = sanitized.gsub(/\*{1,3}/, '').gsub(/_{1,3}/, '').gsub(/^#+\s/, '') if sanitized
    {
      body: sanitized,
      number: number,
      law_id: law_id,
      law_name: law&.name,
      law_creation_number: law&.creation_number,
      law_status: law&.status,
      law_hierarchy: law&.hierarchy,
      law_tag_names: law&.tags&.map(&:name) || []
    }
  end
end