class AddOtherOccupationToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :other_occupation, :string
  end
end
