class ChangeJobIdToBeStringInUsersPreferences < ActiveRecord::Migration[6.1]
  def change
    change_column :users_preferences, :job_id, :string
  end
end
