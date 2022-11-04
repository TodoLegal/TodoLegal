class AddUserPreferenceTagsToUsersPreferences < ActiveRecord::Migration[6.1]
  def change
    add_column :users_preferences, :user_preference_tags, :integer, array: true, default: []
  end
end
