class DocumentEditionHistory < ApplicationRecord
  belongs_to :datapoint
  has_one :document, through: :datapoint
end