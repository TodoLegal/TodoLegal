Rails.application.configure do
  config.after_initialize do
    Bullet.enable        = true
    Bullet.alert         = true
    Bullet.bullet_logger = true
    Bullet.console       = true
    Bullet.rails_logger  = true
    Bullet.add_footer    = true
  end

  config.after_initialize do
     Bullet.enable = true
    # Bullet.sentry = true
     Bullet.alert = true
     Bullet.bullet_logger = true
     Bullet.console = true
     Bullet.rails_logger = true
    #Bullet.honeybadger = true
    #Bullet.bugsnag = true
    #Bullet.appsignal = true
    #Bullet.airbrake = true
    #Bullet.rollbar = true
     Bullet.add_footer = true
     Bullet.skip_html_injection = false
    #Bullet.stacktrace_includes = [ 'your_gem', 'your_middleware' ]
    #Bullet.stacktrace_excludes = [ 'their_gem', 'their_middleware', ['my_file.rb', 'my_method'], ['my_file.rb', 16..20] ]
    #Bullet.slack = { webhook_url: 'http://some.slack.url', channel: '#default', username: 'notifier' }
  end

  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false
  config.action_controller.page_cache_directory = Rails.root.join("public", "cached_pages")

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Show full error reports and disable caching
  config.action_controller.perform_caching = true
  config.cache_store = :mem_cache_store

  # Enable/disable caching. By default caching is disabled.
  # R to toggle caching.
  #if Rails.root.join('tmp', 'caching-dev.txt').exist?
   # config.action_controller.perform_caching = true
   # config.action_controller.enable_fragment_cache_logging = true
    #config.cache_store = :dalli_store
    #config.cache_store = :memory_store

    #config.public_file_server.headers = {
   #   'Cache-Control' => "public, max-age=#{2.days.to_i}"
    #}
  #else
    #config.action_controller.perform_caching = false
    #config.cache_store = :null_store
  #end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :google
  config.action_controller.perform_caching = true
  config.hosts << ENV['SERVER_IP']
  Rails.application.config.hosts << 'devchuco.todolegal.app'
  # Don't care if the mailer can't send.
  config.action_mailer.default_url_options = { host: "devchuco.todolegal.app" }
  config.action_mailer.delivery_method = :mailgun
  config.action_mailer.mailgun_settings = {
    api_key: ENV['MAILGUN_KEY'],
    domain: ENV['MAILGUN_URL']
  # api_host: 'api.eu.mailgun.net'  # Uncomment this line for EU region domains
  }

  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker


end
