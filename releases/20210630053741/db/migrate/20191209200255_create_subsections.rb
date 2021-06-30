class CreateSubsections < ActiveRecord::Migration[6.0]
  def change
    create_table :subsections do |t|
      t.string :number
      t.string :name
      t.integer :position

      t.timestamps
    end
  end
end
