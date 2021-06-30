class RemoveOtherOccupationFromUsers < ActiveRecord::Migration[6.0]
  def change

    remove_column :users, :other_occupation, :string
  end
end
