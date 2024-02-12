class CreateDocumentHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :document_histories do |t|
      t.integer :document_id
      t.integer :user_id
      t.datetime :published_at
      t.text :comments
      
      t.timestamps
    end
  end
end
