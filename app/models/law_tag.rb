class LawTag < ApplicationRecord
  belongs_to :tag
  belongs_to :law
end
