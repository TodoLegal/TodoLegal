class CreateSections < ActiveRecord::Migration[6.0]
  def change
    create_table :sections do |t|
      t.string :number
      t.string :name
      t.integer :position
      t.integer :law_id

      t.timestamps
    end
  end
end
