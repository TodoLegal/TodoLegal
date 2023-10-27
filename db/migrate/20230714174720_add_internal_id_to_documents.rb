class AddInternalIdToDocuments < ActiveRecord::Migration[6.1]
  def change
    add_column :documents, :internal_id, :string, default: ""
  end
end
