class CreateDocumentRelationships < ActiveRecord::Migration[6.0]
  def change
    create_table :document_relationships do |t|
      t.integer :document_1_id
      t.integer :document_2_id
      t.string :relationship

      t.timestamps
    end
  end
end
