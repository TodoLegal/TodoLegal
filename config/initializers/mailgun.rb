require 'mailgun-ruby'

Mailgun.configure do |config|
    config.api_key = ENV['MAILGUN_KEY']
end
