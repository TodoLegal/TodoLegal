class CreateLawAccesses < ActiveRecord::Migration[6.0]
  def change
    create_table :law_accesses do |t|
      t.string :name

      t.timestamps
    end
  end
end
