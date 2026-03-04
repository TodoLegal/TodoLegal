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
  #   3. Otherwise → validate X-Turnstile-Token header (enforced in API-SEC-05)
  def verify_turnstile_token!
    # Bypass: authenticated users already proved identity via Doorkeeper
    return if doorkeeper_token.present?

    # Bypass: Cloudflare Verified Bots (header set by Cloudflare HTTP Request Header
    # Modification Rule — cannot be spoofed, Cloudflare strips it from non-verified requests)
    return if request.headers['X-Verified-Bot'] == 'true'

    # TODO [API-SEC-05]: Enforce Turnstile validation here.
    # For now, log requests without a Turnstile token for observability.
    unless request.headers['X-Turnstile-Token'].present?
      Rails.logger.info "[Turnstile] Unauthenticated request without Turnstile token: #{request.ip} #{request.path}"
    end
  end
end
