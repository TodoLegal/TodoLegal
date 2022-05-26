Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :patch, :put]
  end
end

Rails.application.config.hosts << "test.todolegal.app"
Rails.application.config.hosts << "todolegal.app"
Rails.application.config.hosts << "devchuco.todolegal.app"
Rails.application.config.hosts << "167.71.188.59"