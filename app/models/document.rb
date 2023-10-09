class Document < ApplicationRecord
  include PgSearch
  searchkick language: 'spanish'

  has_many :issuer_document_tags, dependent: :destroy
  has_many :document_tags, dependent: :destroy
  has_many :tags, through: :document_tags, dependent: :destroy
  has_one :judgement_auxiliary

  belongs_to :document_type

  has_one_attached :original_file

  pg_search_scope :search_by_all,
                  against: [:name, :description, :publication_number],
                  ignoring: :accents,
                  using: {
                    tsearch: {
                      dictionary: 'spanish'
                    }
                  }

  def generate_friendly_url
    [name.parameterize.tr('-',''), publication_number.parameterize.tr('-','')].join('-')
  end

  def search_data
    {
      publication_date: publication_date,
      issue_id: issue_id,
      publication_number: publication_number,
      issuer_document_tags: issuer_document_tags.try(:name),
      document_type_name: document_type.try(:name),
      document_type_alternative_name: document_type.try(:alternative_name), #document_type_alternative_name + issue_id
      name: name,
      description: description,
      short_description: short_description,
      document_tags: tags.map(&:name)
    }
  end
end
