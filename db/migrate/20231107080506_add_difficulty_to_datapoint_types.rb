class AddDifficultyToDatapointTypes < ActiveRecord::Migration[6.1]
  def change
    add_column :datapoint_types, :difficulty, :integer
  end
end
