class Law < ApplicationRecord
  include PgSearch

  belongs_to :law_access
  has_many :books, :dependent => :destroy
  has_many :titles, :dependent => :destroy
  has_many :chapters, :dependent => :destroy
  has_many :sections, :dependent => :destroy
  has_many :subsections, :dependent => :destroy
  has_many :articles, :dependent => :destroy
  has_many :law_tags, :dependent => :destroy
  has_many :law_modifications, :dependent => :destroy
  has_many :tags, through: :law_tags, :dependent => :destroy

  pg_search_scope :search_by_name,
                  against: [:name, :creation_number],
                  ignoring: :accents,
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
