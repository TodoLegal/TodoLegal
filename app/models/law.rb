class Law < ApplicationRecord
  has_many :titles
  has_many :chapters
  has_many :articles
  has_many :law_tags
  has_many :tags, through: :law_tags
end
