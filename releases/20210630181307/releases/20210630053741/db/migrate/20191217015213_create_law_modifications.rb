class CreateLawModifications < ActiveRecord::Migration[6.0]
  def change
    create_table :law_modifications do |t|
      t.integer :law_id
      t.string :name

      t.timestamps
    end
  end
end
