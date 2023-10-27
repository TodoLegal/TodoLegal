class RemoveColumnWithForeignKeyFromDatapoints < ActiveRecord::Migration[6.1]
  def change
    remove_reference :datapoints, :user_permission, index: true, foreign_key: true
  end
end
