class AddSourceAppToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :source_app, :string, default: 'todolegal', null: false
    add_index :users, :source_app
  end
end
