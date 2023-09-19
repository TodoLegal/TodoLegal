class AddStatusAndHierarchyToDocuments < ActiveRecord::Migration[6.1]
  def change
    add_column :documents, :status, :string, default: ""
    add_column :documents, :hierarchy, :string, default: ""
  end
end
