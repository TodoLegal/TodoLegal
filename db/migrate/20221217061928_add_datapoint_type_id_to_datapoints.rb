class AddDatapointTypeIdToDatapoints < ActiveRecord::Migration[6.1]
  def change
    add_column :datapoints, :datapoint_type_id, :integer
  end
end
