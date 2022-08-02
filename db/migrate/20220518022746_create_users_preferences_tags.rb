class CreateUsersPreferencesTags < ActiveRecord::Migration[6.1]
  def change
    create_table :users_preferences_tags do |t|
      t.integer :tag_id

      t.timestamps
    end
  end
end
