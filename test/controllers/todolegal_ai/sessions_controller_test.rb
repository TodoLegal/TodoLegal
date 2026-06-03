# frozen_string_literal: true

require 'test_helper'

module TodolegalAi
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    # ─── Sign-in guard: source_app check ─────────────────────────────────────

    test "todolegal_ai user can sign in successfully" do
      user = users(:ai_user)

      post todolegal_ai_sessions_create_path, params: {
        user: { email: user.email, password: 'Test1234!' }
      }

      assert_redirected_to root_path
      assert_nil flash[:alert]
    end

    test "legacy todolegal user is blocked with a flash alert" do
      user = users(:legacy_user)

      post todolegal_ai_sessions_create_path, params: {
        user: { email: user.email, password: 'Test1234!' }
      }

      assert_redirected_to todolegal_ai_sign_in_path
      assert_equal "Esta cuenta no tiene acceso a TodoLegal AI.", flash[:alert]
    end

    # ─── Sign-in page renders ────────────────────────────────────────────────

    test "GET sign-in renders the sign-in form" do
      get todolegal_ai_sign_in_path
      assert_response :success
    end

    # ─── After sign-in redirect ──────────────────────────────────────────────

    test "after sign-in, returns to stored return_to URL when present" do
      user = users(:ai_user)

      # Store a relative return_to URL (simulating the OAuth authorize flow)
      get todolegal_ai_sign_in_path, params: { return_to: '/oauth/authorize?client_id=abc' }

      post todolegal_ai_sessions_create_path, params: {
        user: { email: user.email, password: 'Test1234!' }
      }

      assert_redirected_to '/oauth/authorize?client_id=abc'
    end

    test "sign-out destroys the session" do
      user = users(:ai_user)
      post todolegal_ai_sessions_create_path, params: {
        user: { email: user.email, password: 'Test1234!' }
      }

      delete todolegal_ai_sign_out_path
      assert_response :redirect
    end
  end
end
