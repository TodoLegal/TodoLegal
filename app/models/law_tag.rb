class LawTag < ApplicationRecord
  belongs_to :tag
  belongs_to :law
  validates :tag_id, uniqueness: { scope: :law_id }
end
