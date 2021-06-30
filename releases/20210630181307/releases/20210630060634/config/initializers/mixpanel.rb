require 'mixpanel-ruby'

$tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_SECRET_KEY'])