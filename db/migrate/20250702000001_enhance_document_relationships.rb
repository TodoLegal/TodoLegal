class EnhanceDocumentRelationships < ActiveRecord::Migration[7.1]
  def change
    change_table :document_relationships do |t|
      t.rename :document_1_id, :source_document_id
      t.rename :document_2_id, :target_document_id
      
      t.rename :relationship, :modification_type
      
      t.text :details, default: ""
      
      t.date :modification_date
    end
    
    # Agregamos índices para optimizar búsquedas
    add_index :document_relationships, :source_document_id
    add_index :document_relationships, :target_document_id
    add_index :document_relationships, :modification_type
  end
end
