class CreatePublisherUserHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :publisher_user_histories do |t|
      t.integer :user_id
      t.integer :total_published_documents
      t.integer :total_time
      t.integer :skipped_documents, array: true, default: []

      t.timestamps
    end
  end
end
