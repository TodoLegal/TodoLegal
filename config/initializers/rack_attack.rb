# frozen_string_literal: true

# ==========================================
# Rack::Attack Configuration
# ==========================================
# Provides application-level rate limiting, abuse prevention, and request filtering.
# Works best when backed by Redis (for consistent throttling across processes).
# ==========================================

class Rack::Attack
  ### 🔹 Redis cache store (required for multi-instance consistency)
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')
  )

  # ------------------------------------------------------------
  # SAFELISTS
  # ------------------------------------------------------------

  # Always trust localhost
  safelist('allow-localhost') { |req| %w[127.0.0.1 ::1].include?(req.ip) }

  # Legitimate crawlers, performance tools, and monitoring services
  safelist('allow-legitimate-bots') do |req|
    ua = req.get_header('HTTP_USER_AGENT').to_s.downcase
    next false if ua.empty?

    legitimate_patterns = %w[
      googlebot bingbot slurp duckduckbot baiduspider yandexbot
      facebookexternalhit twitterbot linkedinbot whatsapp telegrambot
      slackbot discordbot applebot msnbot ia_archiver
      lighthouse pagespeed mixpanel newrelic pingdom datadog
      uptimebot statuscake site24x7
    ]

    legitimate_patterns.any? { |pattern| ua.match?(/\b#{Regexp.escape(pattern)}\b/) }
  end

  # Explicitly ensure safelisted requests are never throttled or blocked
  safelist('always-allow-safelisted') { |req| req.env['rack.attack.safelisted'] }

  # ------------------------------------------------------------
  # THROTTLES
  # ------------------------------------------------------------

    # Registration protection — prevent spam/bot signups
  throttle('registrations/ip', limit: 5, period: 10.minutes) do |req|
    # Web registration: /users/sign_up (Devise default)  
    # API registration: /api/v1/users (Devise API - confirmed via routes)
    req.ip if req.post? && ['/users/sign_up', '/api/v1/users'].include?(req.path)
  end

  # Login throttling by email (protects against credential stuffing)
  throttle('logins/email', limit: 5, period: 20.minutes) do |req|
    if req.post? && ['/users/sign_in', '/api/v1/users/sign_in'].include?(req.path)
      req.params.dig('user', 'email')&.downcase
    end
  end

  # Login throttling by IP (secondary layer)
  throttle('logins/ip', limit: 10, period: 15.minutes) do |req|
    req.ip if req.post? && ['/users/sign_in', '/api/v1/users/sign_in'].include?(req.path)
  end

  # API protection for document endpoints (prevent scraping)
  throttle('api/documents/ip', limit: 200, period: 5.minutes) do |req|
    req.ip if req.path.match?(/^\/api\/v1\/documents/)
  end

  # API protection for search endpoints (prevent abuse)
  # Search happens via query parameters on documents/laws endpoints
  throttle('api/search/ip', limit: 100, period: 5.minutes) do |req|
    req.ip if req.get? && req.path.match?(/^\/api\/v1\/(documents|laws)/) && req.params['query'].present?
  end

  # General API protection (covers all other API endpoints)
  throttle('api/general/ip', limit: 300, period: 5.minutes) do |req|
    req.ip if req.path.start_with?('/api/')
  end

  # Sitemap protection (prevent excessive crawling)
  throttle('sitemap/ip', limit: 10, period: 1.minute) do |req|
    req.ip if req.path.match?(/sitemap.*\.xml$/)
  end

  # ------------------------------------------------------------
  # BLOCKLISTS
  # ------------------------------------------------------------

  # Block clearly malicious or automated scanners (carefully tuned)
  blocklist('block-malicious-user-agents') do |req|
    ua = req.get_header('HTTP_USER_AGENT').to_s.downcase
    next false if ua.empty?

    malicious_patterns = %w[
      python-requests curl/ wget/ httpclient libwww-perl http.rb go-http-client
      masscan nmap nikto sqlmap nuclei scrapy harvester extractor
      phantomjs slimerjs mechanize selenium headlesschrome puppeteer
    ]

    malicious_patterns.any? { |pattern| ua.include?(pattern) } &&
      !req.env['rack.attack.safelisted']
  end

  # Fail2Ban-style IP banning for repeated offenders
  blocklist('block-repeat-violators') do |req|
    Rack::Attack::Fail2Ban.filter(req.ip,
      maxretry: 5,        # number of throttle violations allowed
      findtime: 5.minutes,
      bantime: 1.hour
    ) do
      # only count throttle violations (not general blocks)
      req.env['rack.attack.match_type'] == :throttle
    end
  end

  # ------------------------------------------------------------
  # CUSTOM RESPONSES
  # ------------------------------------------------------------

  # For throttled requests
  self.throttled_responder = lambda do |env|
    retry_after = (env['rack.attack.match_data'] || {})[:period]
    [
      429,
      {
        'Content-Type' => 'application/json',
        'Retry-After' => retry_after.to_s
      },
      [{ error: 'Too many requests. Please try again later.' }.to_json]
    ]
  end

  # For blocked (malicious) requests
  self.blocklisted_responder = lambda do |_env|
    [
      403,
      { 'Content-Type' => 'application/json' },
      [{ error: 'Forbidden' }.to_json]
    ]
  end
end

# ------------------------------------------------------------
# Enable the middleware
# ------------------------------------------------------------
Rails.application.config.middleware.use Rack::Attack

# ------------------------------------------------------------
# LOGGING / OBSERVABILITY
# ------------------------------------------------------------
# Log all rack-attack events for monitoring tools (New Relic, Datadog, etc.)
ActiveSupport::Notifications.subscribe('rack.attack') do |_, _, _, _, payload|
  req = payload[:request]
  match_type = req.env['rack.attack.match_type']
  Rails.logger.info "[Rack::Attack] #{match_type} for #{req.ip} on #{req.path}"
end