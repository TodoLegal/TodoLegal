class Tag < ApplicationRecord
  belongs_to :tag_type
  has_many :law_tags
  has_many :laws, through: :law_tags
  has_many :document_tags
  has_many :documents, through: :document_tags
  has_many :issuer_law_tags
  has_many :issuer_document_tags
  has_many :alternative_tag_names
  has_many :users_preferences_tags

  def to_param
    [id, name.parameterize].join("-")
  end
end
