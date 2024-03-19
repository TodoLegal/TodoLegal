class Datapoint < ApplicationRecord
  has_many :verification_histories, :dependent => :destroy
  belongs_to :datapoint_type
  belongs_to :document
  belongs_to :document_tag, optional: true

  enum :status, { pendiente: 0, correcto: 1, incorrecto: 2 }
end
