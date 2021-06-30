class AddLawIdToSubsection < ActiveRecord::Migration[6.0]
  def change
    add_column :subsections, :law_id, :integer
  end
end
