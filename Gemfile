source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.0'

# My added gems
gem 'newrelic_rpm'
gem 'pg'
gem 'pg_search'
gem 'thin'
gem 'route_translator'
gem 'devise'
gem 'redcarpet'
gem 'hiredis'
gem 'google-api-client'
gem 'whenever', require: false
gem 'exception_notification'
gem 'discordrb'
gem 'stripe'
gem 'rack-mini-profiler'
gem 'dalli'
gem 'simple_token_authentication'
gem 'mixpanel-ruby'
gem "google-cloud-storage", "~> 1.11", require: false
gem 'rack-cors'
gem 'browser'
gem 'kaminari'
gem 'searchkick'
gem 'capistrano'
gem 'capistrano-rails'
gem 'capistrano-passenger'
gem 'capistrano-rbenv'
gem 'capistrano3-nginx'
gem 'capistrano-bundler'
gem 'doorkeeper'
gem 'MailchimpMarketing', :git => 'https://github.com/mailchimp/mailchimp-marketing-ruby.git'
#gem 'rack-cors'
#Support for NewRelic

#Queue management
gem 'sidekiq'
gem 'redis-namespace'
#gem  'foreman'
# For capistrano
gem 'ed25519'
gem 'bcrypt_pbkdf'
gem 'capistrano-env_config'
gem 'elasticsearch'
#Just a session per account gem
gem 'devise-security'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails'
# Use sqlite3 as the database for Active Record
#gem 'sqlite3', '~> 1.4'
# Use Puma as the app server
gem 'puma'
# Use SCSS for stylesheets
gem 'sass-rails'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'
gem 'mailgun-ruby'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'
gem "actionpack-page_caching"
#gem 'rack-cors'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console'
  gem 'listen'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen'

end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
