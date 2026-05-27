# frozen_string_literal: true

require 'test_helper'

module TodolegalAi
  class RegistrationsControllerTest < ActionDispatch::IntegrationTest
    # ─── Feature-flag gate (self-registration disabled by default) ───────

    test "GET sign-up returns 403 invite-only page when self-registration is disabled" do
      # Default: TODOLEGAL_AI_SELF_REGISTRATION_ENABLED is 'false'
      get todolegal_ai_sign_up_path
      assert_response :forbidden
    end

    test "POST sign-up returns 403 when self-registration is disabled" do
      post '/todolegal-ai/sign-up', params: {
        user: {
          first_name: 'Test', last_name: 'User',
          email: 'new@example.com',
          password: 'Test1234!', password_confirmation: 'Test1234!'
        }
      }
      assert_response :forbidden
    end

    # ─── Self-registration enabled ───────────────────────────────────────
    # NOTE: The registration form template (todolegal_ai/registrations/new.html.erb)
    # is not yet built — self-registration is gated by feature flag (default: off).
    # GET and POST tests for the enabled path are skipped until the view is created.

    test "POST sign-up creates a user when self-registration is enabled" do
      skip "Registration view (new.html.erb) not yet built — self-registration is invite-only"
    end

    # ─── Mass-assignment protection ──────────────────────────────────────

    test "source_app cannot be injected via sign-up params" do
      skip "Registration view (new.html.erb) not yet built — self-registration is invite-only"
    end
  end
end
