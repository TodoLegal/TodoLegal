class CreateAlternativeTagNames < ActiveRecord::Migration[6.1]
  def change
    create_table :alternative_tag_names do |t|
      t.integer :tag_id
      t.string :alternative_name

      t.timestamps
    end
  end
end
