# frozen_string_literal: true

require 'test_helper'

module TodolegalAi
  class PasswordsControllerTest < ActionDispatch::IntegrationTest
    # ─── GET forgot-password ─────────────────────────────────────────────

    test "GET forgot-password renders the branded form" do
      get todolegal_ai_forgot_password_path
      assert_response :success
      assert_match 'contraseña', response.body.downcase
    end

    # ─── POST forgot-password: email-enumeration protection ──────────────

    test "POST forgot-password with existing email redirects with neutral flash" do
      user = users(:ai_user)

      post '/todolegal-ai/forgot-password', params: {
        user: { email: user.email }
      }

      assert_redirected_to todolegal_ai_sign_in_path
      assert_match 'Si tu correo está registrado', flash[:notice]
    end

    test "POST forgot-password with non-existing email returns identical redirect (no enumeration)" do
      post '/todolegal-ai/forgot-password', params: {
        user: { email: 'nonexistent@example.com' }
      }

      # Same redirect + same flash as existing-email case — no enumeration vector
      assert_redirected_to todolegal_ai_sign_in_path
      assert_match 'Si tu correo está registrado', flash[:notice]
    end

    # ─── GET reset-password ──────────────────────────────────────────────

    test "GET reset-password renders the edit form with token" do
      get todolegal_ai_reset_password_path, params: { reset_password_token: 'abc123' }
      assert_response :success
      assert_match 'abc123', response.body
    end

    # ─── PATCH reset-password with valid token ───────────────────────────

    test "PATCH reset-password with valid token resets password and redirects to root" do
      user = users(:ai_user)
      token = user.send(:set_reset_password_token)

      patch '/todolegal-ai/reset-password', params: {
        user: {
          reset_password_token: token,
          password: 'NewPass123!',
          password_confirmation: 'NewPass123!'
        }
      }

      assert_redirected_to root_path
    end

    test "PATCH reset-password with invalid token re-renders the form with errors" do
      patch '/todolegal-ai/reset-password', params: {
        user: {
          reset_password_token: 'invalid_token',
          password: 'NewPass123!',
          password_confirmation: 'NewPass123!'
        }
      }

      # Devise re-renders the form (200) when the token is invalid
      assert_response :success
      assert_match 'reset_password_token', response.body
    end

    # ─── Redirect to frontend after reset ────────────────────────────────

    test "after reset redirects to frontend login URL when env var is set" do
      user = users(:ai_user)
      token = user.send(:set_reset_password_token)

      ENV['TODOLEGAL_AI_FRONTEND_LOGIN_URL'] = 'https://frontend.example.test/api/auth/login'

      patch '/todolegal-ai/reset-password', params: {
        user: {
          reset_password_token: token,
          password: 'NewPass123!',
          password_confirmation: 'NewPass123!'
        }
      }

      assert_redirected_to 'https://frontend.example.test/api/auth/login'
    ensure
      ENV.delete('TODOLEGAL_AI_FRONTEND_LOGIN_URL')
    end

    test "after reset falls back to root_path when frontend env var is absent" do
      user = users(:ai_user)
      token = user.send(:set_reset_password_token)

      ENV.delete('TODOLEGAL_AI_FRONTEND_LOGIN_URL')

      patch '/todolegal-ai/reset-password', params: {
        user: {
          reset_password_token: token,
          password: 'NewPass123!',
          password_confirmation: 'NewPass123!'
        }
      }

      assert_redirected_to root_path
    end
  end
end
