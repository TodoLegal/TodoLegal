class AddDescriptionToPermissions < ActiveRecord::Migration[7.1]
  def change
    add_column :permissions, :description, :text, default: ""
  end
end
