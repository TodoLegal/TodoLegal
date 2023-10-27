class DocumentTag < ApplicationRecord
  belongs_to :tag
  belongs_to :document
  validates :tag_id, uniqueness: { scope: :document_id }
end