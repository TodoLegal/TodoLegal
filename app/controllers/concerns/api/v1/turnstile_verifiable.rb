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
    return if request.headers['X-Verified-Bot'] == 'true'

    result = TurnstileVerifier.call(
      token: request.headers['X-Turnstile-Token'],
      remote_ip: request.remote_ip
    )

    unless result.success?
      Rails.logger.info "[Turnstile] Verification failed: #{result.error_message} | IP: #{request.remote_ip} | Path: #{request.path}"

      if ENV['TURNSTILE_ENABLED'] == 'true'
        render json: { error: 'Forbidden' }, status: :forbidden
      end
    end
  end
end
