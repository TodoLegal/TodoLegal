class CreateLaws < ActiveRecord::Migration[6.0]
  def change
    create_table :laws do |t|
      t.string :name

      t.timestamps
    end
  end
end
