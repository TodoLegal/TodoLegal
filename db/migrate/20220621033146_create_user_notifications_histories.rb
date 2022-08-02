class CreateUserNotificationsHistories < ActiveRecord::Migration[6.1]
  def change
    create_table :user_notifications_histories do |t|
      t.integer :user_id
      t.datetime :mail_sent_at
      t.integer :documents_ids  , array: true, default: []
      t.timestamps
    end
  end
end
