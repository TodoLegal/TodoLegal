require 'mixpanel-ruby'

#General Mixpanale tacker
$tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_SECRET_KEY'])

#Tracker for TodoLegal AI
$tracker_ai = Mixpanel::Tracker.new(ENV['TODOLEGAL_AI_MIXPANEL_SECRET_KEY'])