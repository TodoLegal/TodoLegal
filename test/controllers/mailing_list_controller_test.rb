require "test_helper"

class MailingListControllerTest < ActionDispatch::IntegrationTest
  test "should get addEmail" do
    get mailing_list_addEmail_url
    assert_response :success
  end
end
