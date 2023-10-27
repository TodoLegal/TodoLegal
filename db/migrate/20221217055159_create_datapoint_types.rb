class CreateDatapointTypes < ActiveRecord::Migration[6.1]
  def change
    create_table :datapoint_types do |t|
      t.integer :user_permission_id
      t.string :name
      t.integer :priority
      t.text :description
      t.timestamps
    end
  end
end
