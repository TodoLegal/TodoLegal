class Law < ApplicationRecord
  include PgSearch
  
  has_many :books
  has_many :titles
  has_many :chapters
  has_many :sections
  has_many :articles
  has_many :law_tags
  has_many :tags, through: :law_tags

  pg_search_scope :search_by_name,
                  against: [:name, :creation_number],
                  using: {
                    tsearch: {
                      dictionary: "spanish",
                      highlight: {
                        StartSel: '<b style="color:red" class="highlighted">',
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

  def to_param
    [id, name.parameterize].join("-")
  end
end
