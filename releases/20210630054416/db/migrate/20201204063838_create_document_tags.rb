class CreateDocumentTags < ActiveRecord::Migration[6.0]
  def change
    create_table :document_tags do |t|
      t.integer :document_id
      t.integer :tag_id

      t.timestamps
    end
  end
end
