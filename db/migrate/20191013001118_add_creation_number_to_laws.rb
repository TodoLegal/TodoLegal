class AddCreationNumberToLaws < ActiveRecord::Migration[6.0]
  def change
    add_column :laws, :creation_number, :string
  end
end
