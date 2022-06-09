require "administrate/base_dashboard"

class LawDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    law_access: Field::BelongsTo,
    books: Field::HasMany,
    titles: Field::HasMany,
    chapters: Field::HasMany,
    sections: Field::HasMany,
    subsections: Field::HasMany,
    articles: Field::HasMany,
    law_modifications: Field::HasMany,
    issuer_law_tags: Field::HasMany,
    law_tags: Field::HasMany,
    tags: Field::HasMany,
    id: Field::Number,
    name: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    modifications: Field::Text,
    creation_number: Field::String,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    law_access
    books
    titles
    chapters
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    law_access
    books
    titles
    chapters
    sections
    subsections
    articles
    law_modifications
    issuer_law_tags
    law_tags
    tags
    id
    name
    created_at
    updated_at
    modifications
    creation_number
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    law_access
    books
    titles
    chapters
    sections
    subsections
    articles
    law_modifications
    issuer_law_tags
    law_tags
    tags
    name
    modifications
    creation_number
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

  # Overwrite this method to customize how laws are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(law)
  #   "Law ##{law.id}"
  # end
end
