class LawModification < ApplicationRecord
  belongs_to :law
  belongs_to :document, optional: true
  
  # Enum for modification types
  enum modification_type: {
    amend: 'amend',              # Amendment/Reform
    repeal: 'repeal'             # Repeal
  }
  
  # Validaciones
  validates :modification_type, presence: true
  validates :law_id, presence: true
  
  # Callback: update law status when it gets repealed
  after_save :update_law_status, if: -> { saved_change_to_modification_type? && modification_type == 'repeal' }
  
  private
  
  def update_law_status
    # If it's a repeal, update the law's status
    if modification_type == 'repeal'
      law.update(status: 'derogado')
    end
  end
end
