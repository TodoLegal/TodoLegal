class AddPublishToDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :publish, :boolean, default: false
  end
end
