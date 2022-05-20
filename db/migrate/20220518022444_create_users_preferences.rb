class CreateUsersPreferences < ActiveRecord::Migration[6.1]
  def change
    create_table :users_preferences do |t|
      t.integer :user_id
      t.integer :users_preferences_tags_id
      t.datetime :mail_sent_at
      t.integer :mail_frequency

      t.timestamps
    end
  end
end
