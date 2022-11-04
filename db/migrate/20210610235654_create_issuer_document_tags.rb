class CreateIssuerDocumentTags < ActiveRecord::Migration[6.1]
  def change
    create_table :issuer_document_tags do |t|
      t.integer :document_id
      t.integer :tag_id

      t.timestamps
    end
    add_index :issuer_document_tags, [:document_id, :tag_id], unique: true
  end
end
