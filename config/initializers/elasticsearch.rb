Searchkick.client = Elasticsearch::Client.new(
  hosts: ENV["ELASTICSEARCH_URL"],
  retry_on_failure: true,
  transport_options: {
    request: { timeout: 250 },
    ssl: { verify: false }  # ES uses self-signed certs; distribute CA cert + set verify: true for SOC 2 certification
  }
)
