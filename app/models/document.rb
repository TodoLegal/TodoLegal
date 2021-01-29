class Document < ApplicationRecord
  include PgSearch

  has_many :document_tags
  has_many :tags, through: :document_tags, :dependent => :destroy

  has_one_attached :original_file

  pg_search_scope :search_by_all,
                  against: [:name, :description],
                  ignoring: :accents,
                  using: {
                    tsearch: {
                      dictionary: "tl_config"
                    }
                  }

  def generate_friendly_url
    [id, name.parameterize, publication_number.parameterize.tr('-','')].join('-')
  end
end
