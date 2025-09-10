class Document < ApplicationRecord
  include PgSearch
  searchkick language: 'spanish'

  has_many :issuer_document_tags, :dependent => :destroy

  has_many :document_tags, :dependent => :destroy
  has_many :tags, through: :document_tags, :dependent => :destroy

  has_one :judgement_auxiliary
  has_many :document_histories, :dependent => :destroy

  belongs_to :document_type

  # Document-document relationships
  # source relationships are those where this document is the source (i.e., it modifies or repeals another document)
  # target relationships are those where this document is the target (i.e., it is modified or repealed by another document)
  has_many :source_relationships, class_name: 'DocumentRelationship', 
           foreign_key: 'source_document_id', dependent: :destroy
  has_many :target_relationships, class_name: 'DocumentRelationship', 
           foreign_key: 'target_document_id', dependent: :destroy
           
  # Documents that this document modifies or repeals
  has_many :modified_documents, through: :source_relationships, 
           source: :target_document
           
  # Documents that modify or repeal this document
  has_many :modifying_documents, through: :target_relationships, 
           source: :source_document
           
  # Law modification relationships
  has_many :law_modifications, dependent: :destroy
  has_many :modified_laws, through: :law_modifications, source: :law

  has_one_attached :original_file

  # # Validations
  # validates :issue_id, uniqueness: { 
  #   scope: :document_type_id, 
  #   message: "This document already exists for this type",
  #   allow_blank: true 
  # }

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

  # Enum for document statuses
  enum status: {
    vigente: 'vigente',     # In force
    reformado: 'reformado', # Amended
    derogado: 'derogado'    # Repealed
  }
  
  # Helper methods for relationships and statuses

  # Documents that this document has repealed
  def repealed_documents
    source_relationships.where(modification_type: 'repeal').map(&:target_document)
  end

  # Documents that this document has amended
  def amended_documents
    source_relationships.where(modification_type: 'amend').map(&:target_document)
  end

  # Documents that have repealed this document
  def repealing_documents
    target_relationships.where(modification_type: 'repeal').map(&:source_document)
  end

  # Documents that have amended this document
  def amending_documents
    target_relationships.where(modification_type: 'amend').map(&:source_document)
  end

  # Laws that this document has repealed
  def repealed_laws
    law_modifications.where(modification_type: 'repeal').map(&:law)
  end

  # Laws that this document has amended
  def amended_laws
    law_modifications.where(modification_type: 'amend').map(&:law)
  end

  # Check if the document has been repealed
  def repealed?
    status == 'derogado' || target_relationships.where(modification_type: 'repeal').exists?
  end

  # Check if the document has been amended
  def amended?
    status == 'reformado' || target_relationships.where(modification_type: 'amend').exists?
  end

  # Update the document status based on its relationships
  def update_status_from_relationships
    if repealing_documents.any?
      update(status: 'derogado')
    elsif amending_documents.any?
      update(status: 'reformado')
    end
  end

  # Repeal a document
  def repeal_document(target_document, date = Date.today, details = '')
    relationship = source_relationships.create_or_find_by(
      target_document: target_document,
      modification_type: 'repeal',
      modification_date: date,
      details: details
    )
    
    # Update the status of the repealed document
    target_document.update(status: 'derogado')
    
    relationship
  end

  # Amend a document
  def amend_document(target_document, date = Date.today, details = '')
    relationship = source_relationships.create_or_find_by(
      target_document: target_document,
      modification_type: 'amend',
      modification_date: date,
      details: details
    )
    
    # Update the status of the amended document
    target_document.update(status: 'reformado')
    
    relationship
  end

  # Repeal a law
  def repeal_law(law, date = Date.today, details = nil, affected_articles = nil)
    modification = law_modifications.create_or_find_by(
      law: law,
      modification_type: 'repeal',
      modification_date: date
    )
    
    # Update optional fields if provided
    modification_updates = {}
    modification_updates[:details] = details if details
    modification_updates[:affected_articles] = affected_articles if affected_articles
    modification.update(modification_updates) if modification_updates.any?
    
    # Update the law's status
    law.update(status: 'derogado')
    
    modification
  end

  # Amend a law
  def amend_law(law, date = Date.today, details = nil, affected_articles = nil)
    modification = law_modifications.create_or_find_by(
      law: law,
      modification_type: 'amend',
      modification_date: date
    )
    
    # Update optional fields if provided
    modification_updates = {}
    modification_updates[:details] = details if details
    modification_updates[:affected_articles] = affected_articles if affected_articles
    modification.update(modification_updates) if modification_updates.any?
    
    modification
  end
end