class AddIndexToLaws < ActiveRecord::Migration[7.1]
  def change
    add_index :laws, :name
  end
end
