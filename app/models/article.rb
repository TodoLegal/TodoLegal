class CustomRender < Redcarpet::Render::HTML
  def paragraph(text)
    text
  end
end

class Article < ApplicationRecord
  include PgSearch

  belongs_to :law, touch: true

  #pg_search_scope :search_by_body, against: :body

  pg_search_scope :search_by_body_highlighted,
                  against: :body,
                  ignoring: :accents,
                  using: {
                    tsearch: {
                      dictionary: "tl_config",
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
      Redcarpet::Markdown.new(CustomRender, :tables => true)
    end
  end
end
