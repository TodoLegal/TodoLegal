class AddStatusAndHierarchyToLaws < ActiveRecord::Migration[6.1]
  def change
    add_column :laws, :status, :string, default: ""
    add_column :laws, :hierarchy, :string, default: ""
  end
end
