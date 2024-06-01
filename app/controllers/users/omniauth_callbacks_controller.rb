# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Devise::Controllers::Helpers

  def google_oauth2
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
end
