class AddUniqueIndexToLawTags < ActiveRecord::Migration[6.0]
  def change
    add_index :law_tags, [:law_id, :tag_id], unique: true
  end
end