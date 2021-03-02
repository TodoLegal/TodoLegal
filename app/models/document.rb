class Document < ApplicationRecord
  include PgSearch
  searchkick

  has_many :document_tags
  has_many :tags, through: :document_tags, :dependent => :destroy

  has_one_attached :original_file

  pg_search_scope :search_by_all,
                  against: [:name, :description, :publication_number],
                  ignoring: :accents,
                  using: {
                    tsearch: {
                      dictionary: "spanish"
                    }
                  }

  def generate_friendly_url
    [id, name.parameterize, publication_number.parameterize.tr('-','')].join('-')
  end
end
