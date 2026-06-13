# frozen_string_literal: true

# Encapsulates the resource_owner_authenticator logic for the TodoLegal AI
# OAuth flow. Extracted from the Doorkeeper initializer to keep it thin and
# to make this logic independently testable.
#
# Usage in config/initializers/doorkeeper.rb:
#   resource_owner_authenticator { DoorkeeperAiAuthenticator.call(self) }
class DoorkeeperAiAuthenticator
  def self.call(controller)
    new(controller).authenticate
  end

  def initialize(controller)
    @controller = controller
  end

  def authenticate
    if current_user
      # If a non-AI (legacy) user is logged in and hits the AI OAuth flow,
      # sign them out and redirect to the AI sign-in page. 
      if todolegal_ai_flow? && non_ai_user?
        sign_out_and_redirect_to_ai_signin
      else
        current_user
      end
    else
      redirect_unauthenticated
      nil
    end
  end

  private

  delegate :params, :request, :redirect_to, :sign_out, to: :@controller

  def current_user
    @controller.current_user
  end

  def todolegal_ai_flow?
    @todolegal_ai_flow ||= begin
      uid = params[:client_id] || request.env.dig('doorkeeper.pre_auth', 'client', 'uid')
      uid.present? &&
        Doorkeeper::Application.where(uid: uid).where("name LIKE ?", "TodoLegal AI%").exists?
    end
  end

  def non_ai_user?
    current_user.source_app != 'todolegal_ai'
  end

  def sign_out_and_redirect_to_ai_signin
    sign_out current_user
    redirect_to "/todolegal-ai/sign-in?return_to=#{CGI.escape(request.fullpath)}"
    nil
  end

  def redirect_unauthenticated
    return_to = request.fullpath

    if todolegal_ai_flow?
      redirect_to "/todolegal-ai/sign-in?return_to=#{CGI.escape(return_to)}"
    elsif params[:go_to_signup] == "true"
      redirect_to @controller.pricing_path(return_to: request.fullpath)
    else
      redirect_to @controller.new_user_session_url(return_to: request.fullpath)
    end
  end
end
