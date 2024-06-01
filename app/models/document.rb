class Document < ApplicationRecord
  include PgSearch
  searchkick language: 'spanish'

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
    data = {
      name: name,
      description: description,
      short_description: short_description,
      publication_date: publication_date.present? ? publication_date.strftime('%d-%m-%Y').to_date : nil,
      publication_date_dashes: publication_date.present? ? publication_date.strftime('%d-%m-%Y') : nil,
      publication_date_slashes: publication_date.present? ? publication_date.strftime('%d/%m/%Y') : nil,
      issue_id: issue_id,
      publication_number: publication_number,
      document_type_name: document_type&.name,
      document_type_alternative_name: document_type&.alternative_name,
      publish: publish,
      document_tags_name: document_tags.map { |dt| dt&.tag&.name }.compact,
      issuer_document_tags_name: issuer_document_tags.map { |idt| idt.tag&.name }.compact,
    }

    data
  end

  def generate_friendly_url
    [name.parameterize.tr('-',''), publication_number.parameterize.tr('-','')].join('-')
  end
end