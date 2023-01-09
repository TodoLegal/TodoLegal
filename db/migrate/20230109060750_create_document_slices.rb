class CreateDocumentSlices < ActiveRecord::Migration[6.1]
  def change
    create_table :document_slices do |t|
      t.integer :document_id
      t.integer :status
      t.text :comments
      t.datetime :last_verified_at
      t.boolean :is_active

      t.timestamps
    end
  end
end
