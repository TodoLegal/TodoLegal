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

      # ─── Pro permission auto-assignment ───────────────────────────────────

      test "new user creation automatically assigns Pro permission" do
        sign_in @admin

        post todolegal_ai_admin_users_path, params: {
          user: { first_name: 'Test', last_name: 'Pro', email: 'properm@fixtures.example.com' }
        }

        created_user = User.find_by(email: 'properm@fixtures.example.com')
        assert_not_nil created_user
        assert created_user.permissions.exists?(name: 'Pro'), 'Newly invited user should have Pro permission'
      end

      test "upgrade with reset_password assigns Pro permission" do
        sign_in @admin
        user = users(:legacy_user)

        post upgrade_todolegal_ai_admin_user_path(user), params: { reset_password: 'true' }

        user.reload
        assert user.permissions.exists?(name: 'Pro'), 'Upgraded user should have Pro permission'
      end

      test "upgrade preserves existing permissions when granting Pro" do
        sign_in @admin
        user = users(:legacy_user)
        editor_perm = Permission.find_or_create_by!(name: 'Editor')
        user.user_permissions.find_or_create_by!(permission: editor_perm)

        post upgrade_todolegal_ai_admin_user_path(user), params: { reset_password: 'true' }

        user.reload
        assert user.permissions.exists?(name: 'Editor'), 'Editor permission should be preserved after upgrade'
        assert user.permissions.exists?(name: 'Pro'),    'Pro permission should also be granted after upgrade'
      end

      test "upgrade preserves stripe_customer_id" do
        sign_in @admin
        user = users(:legacy_user)
        user.update_column(:stripe_customer_id, 'cus_test_legacy_preserved')

        post upgrade_todolegal_ai_admin_user_path(user), params: { reset_password: 'true' }

        user.reload
        assert_equal 'cus_test_legacy_preserved', user.stripe_customer_id
      end
    end
  end
end
