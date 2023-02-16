class AddsActiveNotificationsToUsersPreferences < ActiveRecord::Migration[6.1]
  def change
    add_column :users_preferences, :active_notifications, :boolean, default: true
  end
end
