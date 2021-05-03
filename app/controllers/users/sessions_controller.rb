# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  require 'uri'
  layout "onboarding"
  include Devise::Controllers::Helpers
  skip_before_action :verify_authenticity_token
  
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
end
