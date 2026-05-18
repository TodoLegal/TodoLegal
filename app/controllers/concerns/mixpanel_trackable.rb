# frozen_string_literal: true

# Provides a privacy-safe Mixpanel distinct ID for controllers that track events.
#
# This concern exposes `pseudonymized_user_id` which returns a SHA-256 hash.
# Usage:
#   include MixpanelTrackable
#   $tracker_ai.track(pseudonymized_user_id, 'Event Name', { ... })
#
# Requires `doorkeeper_token` to be available (Doorkeeper gem).
# Falls back to 'anonymous' for unauthenticated or service-to-service requests.
module MixpanelTrackable
  extend ActiveSupport::Concern

  private

  def pseudonymized_user_id
    raw_id = doorkeeper_token&.resource_owner_id
    return 'anonymous' unless raw_id.present?

    salt = ENV['MIXPANEL_SALT'].presence || Rails.application.secret_key_base
    Digest::SHA256.hexdigest("search-#{raw_id}-#{salt}")
  end
end
