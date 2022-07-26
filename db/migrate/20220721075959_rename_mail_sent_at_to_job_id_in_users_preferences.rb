class RenameMailSentAtToJobIdInUsersPreferences < ActiveRecord::Migration[6.1]
  def change
    rename_column :users_preferences, :mail_sent_at, :job_id
  end
end
