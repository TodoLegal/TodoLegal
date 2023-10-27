class AddFieldsToDocuments < ActiveRecord::Migration[6.0]
  def change
    add_column :documents, :url, :string
    add_column :documents, :publication_date, :date
    add_column :documents, :publication_number, :string
    add_column :documents, :description, :text
  end
end
