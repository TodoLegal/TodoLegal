json.extract! users_preference, :id, :user_id, :users_preferences_tags_id, :mail_sent_at, :mail_frequency, :created_at, :updated_at
json.url users_preference_url(users_preference, format: :json)
