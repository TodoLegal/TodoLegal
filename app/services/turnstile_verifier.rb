# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

# Service for verifying Cloudflare Turnstile tokens server-side.
# Calls the Turnstile siteverify API and caches successful verifications
# per IP in Rails.cache (Redis) for 5 minutes to reduce external HTTP calls.
#
# Usage:
#   result = TurnstileVerifier.call(token: request.headers['X-Turnstile-Token'],
#                                   remote_ip: request.remote_ip)
#   if result.success?
#     # Token is valid
#   else
#     # Token is invalid or missing
#     result.error_message # => "missing_token" / "verification_failed" / "invalid_token"
#   end
#
# Environment variables:
#   TURNSTILE_SECRET_KEY - Cloudflare Turnstile secret key (required for enforcement)
#   TURNSTILE_ENABLED    - Set to "true" to enforce; otherwise log-only mode
#
# @see https://developers.cloudflare.com/turnstile/get-started/server-side-validation/
class TurnstileVerifier < ApplicationService
  SITEVERIFY_URL = 'https://challenges.cloudflare.com/turnstile/v0/siteverify'
  CACHE_TTL = 5.minutes
  CACHE_PREFIX = 'turnstile_verified'
  REQUEST_TIMEOUT = 5 # seconds

  def initialize(token:, remote_ip:)
    @token = token
    @remote_ip = remote_ip
  end

  def call
    # Check cache first — if this IP was recently verified, skip the HTTP call
    if cached_verification?
      return success({ verified: true, source: :cache })
    end

    # No token provided
    if @token.blank?
      return failure('missing_token')
    end

    # No secret key configured — can't verify
    secret_key = ENV['TURNSTILE_SECRET_KEY']
    if secret_key.blank?
      Rails.logger.warn '[Turnstile] TURNSTILE_SECRET_KEY not set — skipping verification'
      return success({ verified: true, source: :no_secret_key })
    end

    # Call Cloudflare siteverify API
    verify_with_cloudflare(secret_key)
  end

  private

  # Check if this IP has a cached successful verification
  # @return [Boolean]
  def cached_verification?
    Rails.cache.read(cache_key).present?
  end

  # Cache a successful verification for this IP
  def cache_verification!
    Rails.cache.write(cache_key, true, expires_in: CACHE_TTL)
  end

  # Redis cache key scoped to this IP
  # @return [String]
  def cache_key
    "#{CACHE_PREFIX}:#{@remote_ip}"
  end

  # Call Cloudflare's siteverify endpoint
  # @param secret_key [String] Turnstile secret key
  # @return [ServiceResult]
  def verify_with_cloudflare(secret_key)
    uri = URI(SITEVERIFY_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = REQUEST_TIMEOUT
    http.read_timeout = REQUEST_TIMEOUT

    request = Net::HTTP::Post.new(uri)
    request.set_form_data({
      'secret' => secret_key,
      'response' => @token,
      'remoteip' => @remote_ip
    })

    response = http.request(request)
    body = JSON.parse(response.body)

    if body['success']
      cache_verification!
      success({ verified: true, source: :cloudflare })
    else
      error_codes = body['error-codes'] || []
      Rails.logger.info "[Turnstile] Verification failed for #{@remote_ip}: #{error_codes.join(', ')}"
      failure('invalid_token', { error_codes: error_codes })
    end
  rescue Net::TimeoutError, Net::OpenTimeout => e
    Rails.logger.error "[Turnstile] Timeout calling siteverify: #{e.message}"
    # On timeout, fail open in log-only mode, fail closed in enforcing mode
    if enforcing?
      failure('verification_failed', { reason: 'timeout' })
    else
      success({ verified: true, source: :timeout_fallback })
    end
  rescue StandardError => e
    Rails.logger.error "[Turnstile] Error calling siteverify: #{e.class} #{e.message}"
    if enforcing?
      failure('verification_failed', { reason: e.message })
    else
      success({ verified: true, source: :error_fallback })
    end
  end

  # Whether Turnstile enforcement is enabled
  # When false, verification failures are logged but not enforced
  # @return [Boolean]
  def enforcing?
    ENV['TURNSTILE_ENABLED'] == 'true'
  end
end
