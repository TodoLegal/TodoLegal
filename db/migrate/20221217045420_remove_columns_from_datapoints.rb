class RemoveColumnsFromDatapoints < ActiveRecord::Migration[6.1]
  def change
    remove_columns :datapoints, :name, :priority
  end
end
