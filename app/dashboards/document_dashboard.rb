require "administrate/base_dashboard"

class DocumentDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    issuer_document_tags: Field::HasMany,
    document_tags: Field::HasMany,
    tags: Field::HasMany,
    judgement_auxiliary: Field::HasOne,
    document_type: Field::BelongsTo,
    original_file: Field::ActiveStorage,
    id: Field::Number,
    name: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    url: Field::String,
    publication_date: Field::Date,
    publication_number: Field::String,
    description: Field::Text,
    short_description: Field::Text,
    full_text: Field::Text,
    start_page: Field::Number,
    end_page: Field::Number,
    position: Field::Number,
    issue_id: Field::String,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    issuer_document_tags
    document_tags
    tags
    judgement_auxiliary
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    issuer_document_tags
    document_tags
    tags
    judgement_auxiliary
    document_type
    original_file
    id
    name
    created_at
    updated_at
    url
    publication_date
    publication_number
    description
    short_description
    full_text
    start_page
    end_page
    position
    issue_id
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    issuer_document_tags
    document_tags
    tags
    judgement_auxiliary
    document_type
    original_file
    name
    url
    publication_date
    publication_number
    description
    short_description
    full_text
    start_page
    end_page
    position
    issue_id
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how documents are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(document)
  #   "Document ##{document.id}"
  # end
end
