class AddIndexesToTags < ActiveRecord::Migration[7.1]
  def change
    add_index :tags, :name
    add_index :tags, :tag_type_id
  end
end
