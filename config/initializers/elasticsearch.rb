Searchkick.client = Elasticsearch::Client.new(
  hosts: "#{ENV['ELASTICSEARCH_SCHEME'] || 'https'}://#{ENV['ELASTICSEARCH_HOST']}:#{ENV['ELASTICSEARCH_PORT']}",
  user: ENV["ELASTICSEARCH_USER"] || "elastic",
  password: ENV["ELASTICSEARCH_PASSWORD"],
  retry_on_failure: true,
  transport_options: {
    request: { timeout: 250 },
    ssl: { verify: ENV["ELASTICSEARCH_SSL_VERIFY"] != "false" }
  }
)
