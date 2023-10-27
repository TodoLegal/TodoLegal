class AddLawAccessIdToLaw < ActiveRecord::Migration[6.0]
  def change
    add_column :laws, :law_access_id, :integer
  end
end
