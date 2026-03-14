# frozen_string_literal: true

# Shared Turnstile verification logic for API v1 Devise-based controllers.
# These controllers inherit from Devise base classes and cannot inherit from
# Api::V1::BaseController, so they include this concern instead.
#
# Usage:
#   class Api::V1::SessionsController < Devise::SessionsController
#     include Api::V1::TurnstileVerifiable
#   end
module Api::V1::TurnstileVerifiable
  extend ActiveSupport::Concern

  included do
    before_action :verify_turnstile_token!
  end

  private

  def verify_turnstile_token!
    return if doorkeeper_token.present?

    if request.headers['X-Verified-Bot'] == 'true'
      Rails.logger.error "[Turnstile] Verified bot bypass: #{request.remote_ip} #{request.user_agent} #{request.path}"
      return
    end

    result = TurnstileVerifier.call(
      token: request.headers['X-Turnstile-Token'],
      remote_ip: request.remote_ip
    )

    if result.success?
      Rails.logger.error "[Turnstile] OK: #{result.data[:source]} | IP: #{request.remote_ip} | Path: #{request.path}"
    else
      Rails.logger.error "[Turnstile] Verification failed: #{result.error_message} | IP: #{request.remote_ip} | Path: #{request.path}"

      if ENV['TURNSTILE_ENABLED'] == 'true'
        # reason: 'turnstile_failed' lets the React retry interceptor distinguish
        # Turnstile rejections from other 403s (e.g. authorization failures),
        # so it only auto-retries when a fresh Turnstile token can fix the issue.
        render json: { error: 'Forbidden', reason: 'turnstile_failed' }, status: :forbidden
      end
    end
  end
end
