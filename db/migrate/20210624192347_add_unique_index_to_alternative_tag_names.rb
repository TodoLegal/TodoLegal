class AddUniqueIndexToAlternativeTagNames < ActiveRecord::Migration[6.1]
  def change
    add_index :alternative_tag_names, [:tag_id, :alternative_name], unique: true
  end
end
