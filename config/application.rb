require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TodoLegal
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.active_job.queue_adapter = :sidekiq

    # Base URLs for search result links — set via env vars per environment.
    # Staging: TODOLEGAL_BASE_URL=https://test.todolegal.app  VALID_BASE_URL=https://test.valid.todolegal.app
    # Production: defaults below (or set env vars explicitly)
    config.x.todolegal_base_url = ENV.fetch('TODOLEGAL_BASE_URL', 'https://todolegal.app')
    config.x.valid_base_url = ENV.fetch('VALID_BASE_URL', 'https://valid.todolegal.app')

  end
end
