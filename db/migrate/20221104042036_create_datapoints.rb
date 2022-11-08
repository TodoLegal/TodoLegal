class CreateDatapoints < ActiveRecord::Migration[6.1]
  def change
    create_table :datapoints do |t|
      t.integer :user_permission_id
      t.string :name
      t.integer :priority

      t.timestamps
    end
  end
end
