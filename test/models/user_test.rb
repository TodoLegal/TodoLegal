require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # --- todolegal_ai_status ---

  test "todolegal_ai_status is 'pending' when user has never signed in" do
    user = users(:ai_pending_user)
    assert_equal 'pending', user.todolegal_ai_status
  end

  test "todolegal_ai_status is 'active' when user has signed in at least once" do
    user = users(:ai_user)
    assert_equal 'active', user.todolegal_ai_status
  end

  # --- migrated_to_todolegal_ai? ---

  test "migrated_to_todolegal_ai? is true for a todolegal_ai user created before launch" do
    user = users(:migrated_user)
    assert user.migrated_to_todolegal_ai?,
      "Expected migrated_user (source_app: todolegal_ai, created before 2026-05-25) to be migrated"
  end

  test "migrated_to_todolegal_ai? is false for a recently created todolegal_ai user" do
    user = users(:ai_user)
    refute user.migrated_to_todolegal_ai?,
      "Expected ai_user (created_at: now) not to be flagged as migrated"
  end

  test "migrated_to_todolegal_ai? is false for a legacy todolegal user" do
    user = users(:legacy_user)
    refute user.migrated_to_todolegal_ai?,
      "Expected legacy_user (source_app: todolegal) not to be flagged as migrated"
  end

  # --- admin? ---

  test "admin? returns true for user with Admin permission" do
    user = users(:admin_user)
    assert user.admin?, "Expected admin_user to have admin? == true"
  end

  test "admin? returns false for user without Admin permission" do
    user = users(:ai_user)
    refute user.admin?, "Expected ai_user (no permission) to have admin? == false"
  end
end
