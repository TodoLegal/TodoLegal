# frozen_string_literal: true

# Shared concern for all TodoLegal AI auth controllers.
# Sets the isolated Tailwind layout, exposes feature-flag helpers to views,
# and manages the OAuth return_to URL through the sign-in flow.
module TodolegalAiAuth
  extend ActiveSupport::Concern

  included do
    layout 'todolegal_ai'
    helper_method :social_login_enabled?
    helper_method :self_registration_enabled?
  end

  private

  def social_login_enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('TODOLEGAL_AI_SOCIAL_LOGIN_ENABLED', 'true'))
  end

  def self_registration_enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('TODOLEGAL_AI_SELF_REGISTRATION_ENABLED', 'false'))
  end

  # Stash the OAuth authorize URL so it survives through the sign-in redirect chain.
  def store_todolegal_ai_return_to
    session[:todolegal_ai_return_to] = params[:return_to] if params[:return_to].present?
  end

  # Pop the stashed URL (one-time use) so we don't redirect in a loop.
  def stored_todolegal_ai_return_to
    session.delete(:todolegal_ai_return_to)
  end

  # Validate that the return_to URL is a relative path (prevent open redirect).
  # Returns nil if the value looks external or malicious.
  def safe_return_to(url)
    return nil if url.blank?
    uri = URI.parse(url)
    # Allow only relative paths (no scheme/host) or paths to our own host
    uri.relative? ? url : nil
  rescue URI::InvalidURIError
    nil
  end
end
