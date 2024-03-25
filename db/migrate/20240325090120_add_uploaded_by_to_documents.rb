class AddUploadedByToDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :uploaded_by, :string, default: ""
  end
end
