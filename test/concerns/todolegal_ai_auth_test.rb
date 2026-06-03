# frozen_string_literal: true

require 'test_helper'

# Unit tests for the TodolegalAiAuth concern.
# We test safe_return_to and feature-flag helpers by exercising the private
# methods directly on a minimal ActionController subclass (so the `included`
# block's `layout` / `helper_method` calls work).
class TodolegalAiAuthTest < ActiveSupport::TestCase
  class AuthController < ActionController::Base
    include TodolegalAiAuth
    # Expose private methods for testing
    public :safe_return_to, :social_login_enabled?, :self_registration_enabled?
  end

  setup do
    @auth = AuthController.new
  end

  # ─── safe_return_to: open-redirect protection ─────────────────────────

  test "safe_return_to allows relative paths" do
    assert_equal '/oauth/authorize?client_id=abc', @auth.safe_return_to('/oauth/authorize?client_id=abc')
  end

  test "safe_return_to rejects absolute URLs with scheme" do
    assert_nil @auth.safe_return_to('https://evil.com/steal')
  end

  test "safe_return_to rejects protocol-relative URLs" do
    assert_nil @auth.safe_return_to('//evil.com/path')
  end

  test "safe_return_to returns nil for blank input" do
    assert_nil @auth.safe_return_to('')
    assert_nil @auth.safe_return_to(nil)
  end

  test "safe_return_to handles malformed URIs gracefully" do
    assert_nil @auth.safe_return_to('http://[invalid')
  end

  # ─── Feature flags ────────────────────────────────────────────────────

  test "social_login_enabled? defaults to true" do
    ENV.delete('TODOLEGAL_AI_SOCIAL_LOGIN_ENABLED')
    assert @auth.social_login_enabled?
  end

  test "social_login_enabled? respects env override to false" do
    ENV['TODOLEGAL_AI_SOCIAL_LOGIN_ENABLED'] = 'false'
    refute @auth.social_login_enabled?
  ensure
    ENV.delete('TODOLEGAL_AI_SOCIAL_LOGIN_ENABLED')
  end

  test "self_registration_enabled? defaults to false" do
    ENV.delete('TODOLEGAL_AI_SELF_REGISTRATION_ENABLED')
    refute @auth.self_registration_enabled?
  end

  test "self_registration_enabled? respects env override to true" do
    ENV['TODOLEGAL_AI_SELF_REGISTRATION_ENABLED'] = 'true'
    assert @auth.self_registration_enabled?
  ensure
    ENV.delete('TODOLEGAL_AI_SELF_REGISTRATION_ENABLED')
  end
end
