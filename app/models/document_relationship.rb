class DocumentRelationship < ApplicationRecord
  # Document relationships
  belongs_to :source_document, class_name: 'Document'
  belongs_to :target_document, class_name: 'Document'
  
  # Enum for modification types
  enum modification_type: {
    amend: 'amend',              # Amendment
    repeal: 'repeal'             # Repeal
  }
  
  # Validaciones
  validates :modification_type, presence: true
  validates :source_document_id, presence: true
  validates :target_document_id, presence: true
  
  # Evitar relaciones duplicadas
  validates :source_document_id, uniqueness: { 
    scope: [:target_document_id, :modification_type],
    message: "ya tiene esta modificación con el documento destino" 
  }
  
  # Evitar auto-relaciones
  validate :no_self_relationship
  
  private
  
  def no_self_relationship
    if source_document_id == target_document_id
      errors.add(:source_document_id, "no puede modificarse a sí mismo")
    end
  end
end
