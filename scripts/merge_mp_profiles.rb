require 'mixpanel-ruby'

mixpanel = Mixpanel::Tracker.new('MY_MIXPANEL_PROJECT_TOKEN')

# Fetch 10 users from Mixpanel
response = mixpanel.request('engage', {
  'filter_by_segmentation' => 1,
  'session_id' => Time.now.to_i,
  'limit' => 10
})

# Extract the distinct IDs and email fields of the users
user_data = response['results'].map { |user| { distinct_id: user['$distinct_id'], email: user['$properties']['$email'] } }

# Perform the merge operation for each user
user_data.each do |user|
  distinct_id = user[:distinct_id]
  email = user[:email]

  mixpanel.alias(distinct_id, email)

  puts "User: distinct_id=#{distinct_id}, email=#{email}"
end