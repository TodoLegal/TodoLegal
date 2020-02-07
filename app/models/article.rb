class Article < ApplicationRecord
  include PgSearch

  belongs_to :law

  #pg_search_scope :search_by_body, against: :body

  pg_search_scope :search_by_body,
                  against: :body,
                  using: {
                    tsearch: {
                      dictionary: "spanish",
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


  pg_search_scope :roughly_spelled_like,
  against: :body,
  using: {
    trigram: {
      threshold: 0.01,
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
      Redcarpet::Markdown.new(Redcarpet::Render::HTML, :tables => true)
    end
  end
end
