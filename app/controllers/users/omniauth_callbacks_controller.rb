# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Devise::Controllers::Helpers

  def google_oauth2
    # Handle authentication inline for TodoLegal AI origin — OmniAuth data
    # only exists in the original callback request and cannot survive a redirect.
    if todolegal_ai_origin?
      handle_todolegal_ai_social_login('Google')
      return
    end

    user = User.from_google(from_google_params)
    
    if user.present?
      sign_out_all_scopes
      session[:return_to] = request.env['omniauth.params']['return_to']

      session[:go_to_checkout] = 'true' if request.env['omniauth.params']['go_to_checkout'] == 'true'
      session[:go_to_law] = 'true' if request.env['omniauth.params']['go_to_law'] == 'true'
      session[:is_monthly] = 'true' if request.env['omniauth.params']['is_monthly'] == 'true'
      session[:is_annually] = 'true' if request.env['omniauth.params']['is_annually'] == 'true'
      session[:pricing_onboarding] = 'true' if request.env['omniauth.params']['pricing_onboarding'] == 'true'
      session[:is_onboarding] = 'true' if request.env['omniauth.params']['is_onboarding'] == 'true'

      flash[:notice] = t 'devise.omniauth_callbacks.success', kind: 'Google'
      sign_in_and_redirect user, event: :authentication
    else
      flash[:alert] = t 'devise.omniauth_callbacks.failure', kind: 'Google', reason: "#{auth.info.email} is not authorized."
      redirect_to new_user_session_path
    end
  end

  def microsoft_office365
    if todolegal_ai_origin?
      handle_todolegal_ai_social_login('Microsoft')
      return
    end

    user = User.from_microsoft(from_microsoft_params)
    
    if user.present?
      sign_out_all_scopes
      session[:return_to] = request.env['omniauth.params']['return_to']

      session[:go_to_checkout] = 'true' if request.env['omniauth.params']['go_to_checkout'] == 'true'
      session[:go_to_law] = 'true' if request.env['omniauth.params']['go_to_law'] == 'true'
      session[:is_monthly] = 'true' if request.env['omniauth.params']['is_monthly'] == 'true'
      session[:is_annually] = 'true' if request.env['omniauth.params']['is_annually'] == 'true'
      session[:pricing_onboarding] = 'true' if request.env['omniauth.params']['pricing_onboarding'] == 'true'
      session[:is_onboarding] = 'true' if request.env['omniauth.params']['is_onboarding'] == 'true'
      
      flash[:notice] = t 'devise.omniauth_callbacks.success', kind: 'Microsoft'
      sign_in_and_redirect user, event: :authentication
    else
      flash[:alert] = t 'devise.omniauth_callbacks.failure', kind: 'Microsoft', reason: "#{auth.info.email} is not authorized."
      redirect_to new_user_session_path
    end
  end

   def from_google_params
     @from_google_params ||= {
        uid: auth.uid,
        email: auth.info.email,
        first_name: auth.info.first_name,
        last_name: auth.info.last_name
     }
   end

  def from_microsoft_params
    @from_microsoft_params ||= {
      uid: auth.uid,
      email: auth.info.email,
      first_name: auth.info.first_name,
      last_name: auth.info.last_name
    }
  end

   def auth
      @auth ||= request.env['omniauth.auth']
   end

  # Find-only social login for TodoLegal AI — does NOT auto-create accounts.
  # Account creation is admin-controlled; only users with source_app == 'todolegal_ai'
  # are allowed through.
  def handle_todolegal_ai_social_login(provider)
    email = auth.info.email
    user = User.find_by(email: email)

    if user.present? && user.source_app == 'todolegal_ai'
      # Read session BEFORE sign_out_all_scopes — Warden resets the entire
      # session on logout, so any value read after that call returns nil.
      return_to = session.delete(:todolegal_ai_return_to)

      sign_out_all_scopes
      flash[:notice] = t 'devise.omniauth_callbacks.success', kind: provider

      # Use sign_in + explicit redirect rather than sign_in_and_redirect.
      # sign_in_and_redirect dispatches through ApplicationController#after_sign_in_path_for,
      # which checks session[:return_to] (the legacy app's key) and falls through
      # to signed_in_path when that key is absent.
      # The AI flow uses session[:todolegal_ai_return_to] — a separate key read above.
      sign_in(user, event: :authentication)
      redirect_to(safe_todolegal_ai_return_to(return_to) || '/todolegal-ai/sign-in')
    else
      flash[:alert] = "No se encontró una cuenta de TodoLegal AI con este correo."
      redirect_to '/todolegal-ai/sign-in'
    end
  end

  # OmniAuth stores origin in the session, so it survives failure redirects
  # (unlike omniauth.auth which is request-scoped only).
  def failure
    if todolegal_ai_origin?
      flash[:alert] = "Error de autenticación. Intenta nuevamente."
      redirect_to '/todolegal-ai/sign-in'
    else
      super
    end
  end

  private

  # Returns true when the social login button was clicked from the TodoLegal AI sign-in page.
  # The OmniAuth `origin` param is set in the _social_login partial.
  def todolegal_ai_origin?
    origin = request.env['omniauth.origin'].to_s
    origin.include?('todolegal-ai')
  end

  # Open-redirect guard — mirrors TodolegalAiAuth#safe_return_to.
  # Rejects absolute URLs so only relative paths (e.g. /oauth/authorize?...)
  # survive. Cannot include the full concern here because it would force
  # the todolegal_ai layout on legacy OmniAuth callbacks.
  def safe_todolegal_ai_return_to(url)
    return nil if url.blank?
    uri = URI.parse(url)
    uri.relative? && uri.host.nil? ? url : nil
  rescue URI::InvalidURIError
    nil
  end
end

