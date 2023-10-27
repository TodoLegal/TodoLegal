class CreateChapters < ActiveRecord::Migration[6.0]
  def change
    create_table :chapters do |t|
      t.integer :position
      t.string :name
      t.string :number
      t.integer :law_id

      t.timestamps
    end
  end
end
