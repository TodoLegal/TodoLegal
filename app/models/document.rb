class Document < ApplicationRecord
  include PgSearch
  searchkick language: "light_spanish"

  has_many :issuer_document_tags, :dependent => :destroy
  has_many :document_tags, :dependent => :destroy
  has_many :tags, through: :document_tags, :dependent => :destroy
  has_one :judgement_auxiliary
  has_many :document_histories, :dependent => :destroy

  belongs_to :document_type

  has_one_attached :original_file

  pg_search_scope :search_by_all,
                  against: [:name, :description, :publication_number],
                  ignoring: :accents,
                  using: {
                    tsearch: {
                      dictionary: "spanish"
                    }
                  }

  def search_data
    {
      name: name,
      description: description,
      short_description: short_description,
    }
  end

  def generate_friendly_url
    [name.parameterize.tr('-',''), publication_number.parameterize.tr('-','')].join('-')
  end
end
