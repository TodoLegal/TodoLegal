class AddIsTagAvailableToUsersPreferencesTags < ActiveRecord::Migration[6.1]
  def change
    add_column :users_preferences_tags, :is_tag_available, :boolean
  end
end
