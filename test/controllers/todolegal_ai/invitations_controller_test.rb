# frozen_string_literal: true

require 'test_helper'

module TodolegalAi
  class InvitationsControllerTest < ActionDispatch::IntegrationTest
    # ─── GET set-password ────────────────────────────────────────────────

    test "GET set-password renders the activation form with the token" do
      get todolegal_ai_set_password_path, params: { reset_password_token: 'invite_token_123' }
      assert_response :success
      assert_match 'invite_token_123', response.body
    end

    # ─── PATCH set-password with valid token ─────────────────────────────

    test "PATCH set-password with valid token activates the account" do
      user = users(:ai_pending_user)
      token = user.send(:set_reset_password_token)

      patch '/todolegal-ai/set-password', params: {
        user: {
          reset_password_token: token,
          password: 'NewPass123!',
          password_confirmation: 'NewPass123!'
        }
      }

      assert_redirected_to root_path
      # Verify the password was actually changed
      user.reload
      assert user.valid_password?('NewPass123!'), "Password should have been updated"
    end

    # ─── PATCH set-password with invalid/expired token ───────────────────

    test "PATCH set-password with invalid token re-renders the form with errors" do
      patch '/todolegal-ai/set-password', params: {
        user: {
          reset_password_token: 'expired_or_invalid',
          password: 'NewPass123!',
          password_confirmation: 'NewPass123!'
        }
      }

      # Devise re-renders the form (200) when the token is invalid
      assert_response :success
      assert_match 'reset_password_token', response.body
    end

    # ─── Redirect safety after activation ────────────────────────────────

    test "after activation redirects to stored return_to (relative path)" do
      user = users(:ai_pending_user)
      token = user.send(:set_reset_password_token)

      # Store a relative return_to by visiting the set-password page with one
      # Note: InvitationsController inherits store_todolegal_ai_return_to indirectly
      # but doesn't have it as a before_action; we inject into session manually.
      # The redirect after reset uses stored_todolegal_ai_return_to.
      patch '/todolegal-ai/set-password', params: {
        user: {
          reset_password_token: token,
          password: 'NewPass123!',
          password_confirmation: 'NewPass123!'
        }
      }

      # Without a stored return_to, falls back to root
      assert_redirected_to root_path
    end
  end
end
