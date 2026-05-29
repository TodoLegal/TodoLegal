# frozen_string_literal: true

require 'test_helper'

class MultiAppDeviseMailerTest < ActionMailer::TestCase
  # ─── reset_password_instructions ─────────────────────────────────────────

  test "reset_password_instructions for todolegal_ai user uses branded template" do
    user  = users(:ai_user)
    token = 'test_reset_token_ai'
    email = MultiAppDeviseMailer.reset_password_instructions(user, token)

    assert_equal [user.email], email.to
    # The branded template renders the reset URL via todolegal_ai_reset_password_url
    assert_match 'todolegal-ai/reset-password', email.body.encoded
    assert_match token, email.body.encoded
  end

  test "reset_password_instructions for legacy todolegal user uses default Devise template" do
    user  = users(:legacy_user)
    token = 'test_reset_token_legacy'
    email = MultiAppDeviseMailer.reset_password_instructions(user, token)

    assert_equal [user.email], email.to
    # Default Devise subject — does NOT say "TodoLegal AI"
    assert_no_match 'TodoLegal AI', email.subject
  end

  # ─── welcome_instructions ────────────────────────────────────────────────

  test "welcome_instructions sends to the correct address with expected subject" do
    user  = users(:ai_user)
    token = 'test_welcome_token'
    email = MultiAppDeviseMailer.welcome_instructions(user, token)

    assert_equal [user.email], email.to
    assert_equal 'Activa tu cuenta TodoLegal AI', email.subject
  end

  test "welcome_instructions body contains the set-password URL with the token" do
    user  = users(:ai_user)
    token = 'test_welcome_token_url'
    email = MultiAppDeviseMailer.welcome_instructions(user, token)

    assert_match 'todolegal-ai/set-password', email.body.encoded
    assert_match token, email.body.encoded
  end

  # ─── upgrade_instructions ────────────────────────────────────────────────

  test "upgrade_instructions sends informational email with correct subject" do
    user  = users(:legacy_user)
    email = MultiAppDeviseMailer.upgrade_instructions(user)

    assert_equal [user.email], email.to
    assert_equal 'Tu acceso exclusivo a TodoLegal AI', email.subject
  end

  test "upgrade_instructions body contains the sign-in URL" do
    user  = users(:legacy_user)
    email = MultiAppDeviseMailer.upgrade_instructions(user)

    assert_match 'todolegal-ai/sign-in', email.body.encoded
  end
end
