# frozen_string_literal: true

# Base controller for all API v1 endpoints.
# Provides shared configuration and security filters for the API namespace.
#
# All API controllers should inherit from this class instead of ApplicationController.
# Devise-based controllers (SessionsController, RegistrationsController) cannot inherit
# from this class directly — they use the Api::V1::TurnstileVerifiable concern instead.
class Api::V1::BaseController < ApplicationController
  protect_from_forgery with: :null_session
  include ApplicationHelper

  # Turnstile verification will be enforced in API-SEC-05.
  # Currently a no-op that logs requests without a token for observability.
  before_action :verify_turnstile_token!

  private

  # Verifies that the request comes from a legitimate source.
  # Three bypass paths:
  #   1. Valid Doorkeeper token present → authenticated user, skip
  #   2. Cloudflare Verified Bot header → Googlebot, Bingbot, etc., skip
  #   3. Otherwise → validate X-Turnstile-Token header via TurnstileVerifier
  #
  # Currently in log-only mode (TURNSTILE_ENABLED != 'true').
  # Set TURNSTILE_ENABLED=true to enforce and return 403 on failure.
  def verify_turnstile_token!
    # Bypass: authenticated users already proved identity via Doorkeeper
    return if doorkeeper_token.present?

    # Bypass: Cloudflare Verified Bots (header set by Cloudflare Transform Rule
    # using cf.client.bot — cannot be spoofed, Cloudflare strips it from non-verified requests)
    if request.headers['X-Verified-Bot'] == 'true'
      Rails.logger.info "[Turnstile] Verified bot bypass: #{request.remote_ip} #{request.user_agent} #{request.path}"
      return
    end

    # Validate Turnstile token via TurnstileVerifier service
    result = TurnstileVerifier.call(
      token: request.headers['X-Turnstile-Token'],
      remote_ip: request.remote_ip
    )

    if result.success?
      Rails.logger.info "[Turnstile] OK: #{result.data[:source]} | IP: #{request.remote_ip} | Path: #{request.path}"
    else
      Rails.logger.info "[Turnstile] Verification failed: #{result.error_message} | IP: #{request.remote_ip} | Path: #{request.path}"

      if ENV['TURNSTILE_ENABLED'] == 'true'
        render json: { error: 'Forbidden' }, status: :forbidden
      end
    end
  end
end
