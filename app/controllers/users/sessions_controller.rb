# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  require 'uri'
  layout "onboarding"
  include Devise::Controllers::Helpers
  skip_before_action :verify_authenticity_token
  # before_action :already_logged_in
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  def new
    @go_to_document = params["go_to_document"]
    session[:return_to] = params[:return_to] if params[:return_to]
    super
  end


  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
  def already_logged_in
    Warden::Manager.after_set_user only: :fetch do |record, warden, options|
      scope = options[:scope]
      if record.devise_modules.include?(:session_limitable) &&
        warden.authenticated?(scope) &&
        options[:store] != false
       if record.unique_session_id != warden.session(scope)['unique_session_id'] &&
          !record.skip_session_limitable? && 
          !warden.session(scope)['devise.skip_session_limitable']
         Rails.logger.warn do
           '[devise-security][session_limitable] session id mismatch: '\
           "expected=#{record.unique_session_id.inspect} "\
           "actual=#{warden.session(scope)['unique_session_id'].inspect}"
         end
        #  redirect_to '/users/edit'
         warden.raw_session.clear
         warden.logout(scope)
         throw :warden, scope: scope, message: :session_limited
       end
      end
    end
  end
end
