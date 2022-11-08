class AddUserPermissionToDatapoints < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key :datapoints, :user_permissions
  end
end
