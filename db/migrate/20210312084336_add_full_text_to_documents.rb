class AddFullTextToDocuments < ActiveRecord::Migration[6.1]
  def change
    add_column :documents, :full_text, :text
  end
end
