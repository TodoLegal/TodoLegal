class AddStartPageToDocuments < ActiveRecord::Migration[6.1]
  def change
    add_column :documents, :start_page, :integer
  end
end
