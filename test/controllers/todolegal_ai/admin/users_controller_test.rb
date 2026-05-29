# frozen_string_literal: true

require 'test_helper'

module TodolegalAi
  module Admin
    class UsersControllerTest < ActionDispatch::IntegrationTest
      include Devise::Test::IntegrationHelpers
      include ActiveJob::TestHelper

      setup do
        @admin = users(:admin_user)
      end

      # ─── Access control ───────────────────────────────────────────────────

      test "unauthenticated request redirects to root" do
        get todolegal_ai_admin_users_path
        assert_redirected_to root_path
      end

      test "non-admin user is redirected to root with unauthorized alert" do
        sign_in users(:ai_user)
        get todolegal_ai_admin_users_path
        assert_redirected_to root_path
        assert_equal "Acceso no autorizado.", flash[:alert]
      end

      # ─── Index ────────────────────────────────────────────────────────────

      test "admin can view the users index" do
        sign_in @admin
        get todolegal_ai_admin_users_path
        assert_response :success
      end

      # ─── Create: new email ────────────────────────────────────────────────

      test "admin can invite a new user — creates record and enqueues welcome email" do
        sign_in @admin

        assert_difference('User.count', 1) do
          assert_enqueued_emails 1 do
            post todolegal_ai_admin_users_path, params: {
              user: { first_name: 'Ana', last_name: 'Lopez', email: 'newuser@fixtures.example.com' }
            }
          end
        end

        created_user = User.find_by(email: 'newuser@fixtures.example.com')
        assert_not_nil created_user
        assert_equal 'todolegal_ai', created_user.source_app
        assert_redirected_to todolegal_ai_admin_user_path(created_user)
        assert_match 'correo de bienvenida', flash[:notice]
      end

      # ─── Create: duplicate todolegal_ai email ─────────────────────────────

      test "inviting an already-registered todolegal_ai email renders :new with error" do
        sign_in @admin

        assert_no_difference('User.count') do
          post todolegal_ai_admin_users_path, params: {
            user: { first_name: 'Dup', last_name: 'User', email: users(:ai_user).email }
          }
        end

        assert_response :unprocessable_entity
      end

      # ─── Create: existing legacy user → upgrade confirmation ─────────────

      test "inviting an existing legacy email renders :confirm_upgrade" do
        sign_in @admin

        assert_no_difference('User.count') do
          post todolegal_ai_admin_users_path, params: {
            user: { first_name: 'Legacy', last_name: 'User', email: users(:legacy_user).email }
          }
        end

        assert_response :success
      end

      # ─── Upgrade with reset_password ──────────────────────────────────────

      test "upgrade with reset_password=true migrates source_app and enqueues welcome email" do
        sign_in @admin
        user = users(:legacy_user)

        assert_enqueued_emails 1 do
          post upgrade_todolegal_ai_admin_user_path(user), params: { reset_password: 'true' }
        end

        user.reload
        assert_equal 'todolegal_ai', user.source_app
        assert_redirected_to todolegal_ai_admin_user_path(user)
        assert_match 'link de contraseña', flash[:notice]
      end

      # ─── Upgrade without reset_password ───────────────────────────────────

      test "upgrade without reset_password migrates source_app and enqueues upgrade email" do
        sign_in @admin

        # Create a second legacy user to avoid changing legacy_user used in other tests
        other_legacy = User.create!(
          email: 'other_legacy@fixtures.example.com',
          source_app: 'todolegal',
          password: 'Test1234!',
          password_confirmation: 'Test1234!'
        )
        other_legacy.update_column(:confirmed_at, 1.year.ago)

        assert_enqueued_emails 1 do
          post upgrade_todolegal_ai_admin_user_path(other_legacy)
        end

        other_legacy.reload
        assert_equal 'todolegal_ai', other_legacy.source_app
        assert_redirected_to todolegal_ai_admin_user_path(other_legacy)
        assert_match 'email de bienvenida exclusivo', flash[:notice]
      end
    end
  end
end
