class AddModificationsToLaws < ActiveRecord::Migration[6.0]
  def change
    add_column :laws, :modifications, :text
  end
end
