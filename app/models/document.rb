# frozen_string_literal: true

# Documents uses both `searchkick`and `pg_search` gems.
class Document < ApplicationRecord
  include PgSearch
  searchkick language: 'light_spanish', mappings: {
    properties: {
      publication_date: {
        type: 'date',
        format: 'yyyy/MM/dd||yyyy-MM-dd'
      }
    }
  }

  has_many :issuer_document_tags, dependent: :destroy
  has_many :tags_through_issuer, through: :issuer_document_tags, source: :tag
  has_many :document_tags, dependent: :destroy
  has_many :tags, through: :document_tags
  has_one :judgement_auxiliary
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
      publication_date: publication_date,
      issue_id: issue_id,
      publication_number: publication_number,
      issuer_document_tag: tags_through_issuer.map(&:name),
      document_tags: tags.map(&:name),
      short_description: short_description,
      document_type_name: document_type&.name,
      name: name,
      description: description
    }
  end

  def generate_friendly_url
    [name.parameterize.tr('-',''), publication_number.parameterize.tr('-','')].join('-')
  end
end
