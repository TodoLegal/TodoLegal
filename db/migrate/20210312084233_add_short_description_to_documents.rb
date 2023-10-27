class AddShortDescriptionToDocuments < ActiveRecord::Migration[6.1]
  def change
    add_column :documents, :short_description, :text
  end
end
