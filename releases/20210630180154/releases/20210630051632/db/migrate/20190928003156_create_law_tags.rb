class CreateLawTags < ActiveRecord::Migration[6.0]
  def change
    create_table :law_tags do |t|
      t.integer :law_id
      t.integer :tag_id

      t.timestamps
    end
  end
end
