User.all.each do |user|
  user_trial = UserTrial.create(user_id: user.id)
  if user.user_preferences && user.preferences.updated_at > 2.weeks.ago
    user.user_trials.active = false
  end
end

User.all.each do |user|
  user_trial = UserTrial.create(user_id: user.id)
end