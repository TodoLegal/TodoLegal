class Tag < ApplicationRecord
  belongs_to :tag_type
  has_many :law_tags
  has_many :laws, through: :law_tags
end
