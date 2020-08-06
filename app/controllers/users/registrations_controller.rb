# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  layout "onboarding"
  include Devise::Controllers::Helpers
  #skip_before_filter :verify_authenticity_token, :only => :create
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  def new
    super
    if params[:go_to_law]
      session[:redirect_to_law] = params[:go_to_law]
    end
  end

  # POST /resource
  def create
    validateOccupationParam (params)
    $discord_bot.send_message($discord_bot_channel, "Se ha registrado un nuevo usuario :tada:")
    super
  end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  def update
    validateOccupationParam (params)
    super
  end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
  # end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    session[:user_just_signed_up] = true
    invite_friends_path(is_onboarding:true)
  end

  def after_update_path_for(resource)
    edit_user_registration_path
  end

  #The path used after edit
  # def afer_update_path_for(resource)
  #   root_path
  # end
  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
  
  def update_resource(resource, params)
    if params["password"]&.present? or params["email"]&.present?
      return super
    else
      resource.update_without_password(params.except("current_password"))
    end
  end

  def validateOccupationParam params
    if params[:other_occupation]&.present?
      params[:user][:occupation].replace(params[:other_occupation])
    end
    if params[:user][:occupation] && params[:user][:occupation] == ""
      params[:user][:occupation].replace("Otro")
    end
  end
end
