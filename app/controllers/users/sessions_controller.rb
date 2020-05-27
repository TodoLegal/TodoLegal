# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  layout "onboarding"
  include Devise::Controllers::Helpers
  skip_before_action :verify_authenticity_token
  
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  def new
    super
    if params[:go_to_law]
      session[:redirect_to_law] = params[:go_to_law]
    end
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
