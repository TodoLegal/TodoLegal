class RemoveUsersPreferencesTagsIdFromUsersPreferences < ActiveRecord::Migration[6.1]
  def change
    remove_column :users_preferences, :users_preferences_tags_id, :integer
  end
end
