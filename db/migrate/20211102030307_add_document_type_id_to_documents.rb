class AddDocumentTypeIdToDocuments < ActiveRecord::Migration[6.1]
  def change
    add_column :documents, :document_type_id, :integer
  end
end
