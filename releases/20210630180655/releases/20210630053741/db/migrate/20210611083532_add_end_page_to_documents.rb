class AddEndPageToDocuments < ActiveRecord::Migration[6.1]
  def change
    add_column :documents, :end_page, :integer
  end
end
