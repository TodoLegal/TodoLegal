class AddUniqueIndexToDocumentTags < ActiveRecord::Migration[6.0]
  def change
    add_index :document_tags, [:document_id, :tag_id], unique: true
  end
end
