User.all.each do |user|
  user_trial = UserTrial.create(user_id: user.id)
  is_user_pro = user.stripe_customer_id || user.permissions.find_by(name: "Pro")
  if user.users_preference && user.users_preference.created_at < 2.weeks.ago
    user.user_trial.trial_start = DateTime.now
    user.user_trial.trial_end = DateTime.now + 2.weeks
    user.user_trial.active = false
  elsif user.users_preference && user.users_preference.created_at > 2.weeks.ago
    user.user_trial.trial_start = user.users_preference.created_at
    user.user_trial.trial_end = user.users_preference.created_at + 2.week
    user.user_trial.active = true
  end
end

User.all.each do |user|

  user_trial = UserTrial.create(user_id: user.id)
end