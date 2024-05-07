# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  layout "onboarding"
  include Devise::Controllers::Helpers
  include ApplicationHelper
  #skip_before_filter :verify_authenticity_token, :only => :create
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  def new
    @go_to_law = params[:go_to_law]
    @go_to_checkout = params[:go_to_checkout]
    @is_monthly = params[:is_monthly]
    @is_annually = params[:is_annually]
    @is_student = params[:is_student]
    @pricing_onboarding = params[:pricing_onboarding]
    # session[:return_to] = params[:return_to] if params[:return_to]
    super

  end

  # POST /resource
  def create
    validateOccupationParam (params)
    super
  end

  # GET /resource/edit
  def edit
    @has_pro_permission = current_user_is_pro
    if current_user and current_user.stripe_customer_id
      begin
        @customer = Stripe::Customer.retrieve(current_user.stripe_customer_id)
        @current_user_plan_is_active = current_user_plan_is_active @customer
        if @customer.subscriptions.data.size > 0
          if @customer.subscriptions.data.first.cancel_at
            @cancel_at = Time.at(@customer.subscriptions.data.first.cancel_at)
            @cancel_at_year = @cancel_at.year
            @cancel_at_month = @cancel_at.month
            @cancel_at_day = @cancel_at.day
          end
          if @customer.subscriptions.data.first.current_period_end
            @current_period_end = Time.at(@customer.subscriptions.data.first.current_period_end)
            @current_period_end_year = @current_period_end.year
            @current_period_end_month = @current_period_end.month
            @current_period_end_day = @current_period_end.day
          end
        end
      rescue => e
        Rails.logger.error e.message
        @customer = nil
        @current_user_plan_is_active = false
      end
    end
    super
    update_mixpanel_user current_user
  end

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
    if current_user
      update_mixpanel_user current_user
      $tracker.track(current_user.id, 'Sign Up', {
      '$email'            => current_user.email,
      'first_name'      => current_user.first_name,
      'last_name'      => current_user.last_name,
      'phone_number'    => current_user.phone_number,
      'current_sign_in_at'      => current_user.current_sign_in_at,
      'last_sign_in_at'      => current_user.last_sign_in_at,
      'current_sign_in_ip'      => current_user.current_sign_in_ip,
      'last_sign_in_ip'      => current_user.last_sign_in_ip,
      'receive_information_emails'      => current_user.receive_information_emails
      })
    
      if ENV['MAILGUN_KEY']
        current_user.send_confirmation_instructions
      end
    end

    if $discord_bot
      $discord_bot.send_message($discord_bot_channel_notifications, "Se ha registrado un nuevo usuario :tada:")
    end

    #TODO
    #Validate student email.

    session[:user_just_signed_up] = true
    if params[:pricing_onboarding]
      #TODO 
      #Otro if igual al primero con un && is_student y que dentro del envie is_student de param en lugar de is_monthly
      if !params[:is_monthly].blank?
        user_trial = UserTrial.create(user_id: current_user.id, trial_start: DateTime.now, trial_end: DateTime.now + 2.weeks, active: false)
        users_preferences_path(is_onboarding:true, go_to_law: params[:go_to_law], is_monthly: params[:is_monthly])
      elsif !params[:is_annually].blank?
        user_trial = UserTrial.create(user_id: current_user.id, trial_start: DateTime.now, trial_end: DateTime.now + 2.weeks, active: false)
        users_preferences_path(is_onboarding:true, go_to_law: params[:go_to_law], is_annually: params[:is_annually])
      else
        #When user chooses Prueba Gratis
        user_trial = UserTrial.create(user_id: current_user.id, trial_start: DateTime.now, trial_end: DateTime.now + 2.weeks, active: true)
        if ENV['MAILGUN_KEY']
          SubscriptionsMailer.welcome_basic_user(current_user).deliver
          SubscriptionsMailer.free_trial_end(current_user).deliver_later(wait_until: user_trial.trial_end - 1.days)
          NotificationsMailer.cancel_notifications(current_user).deliver_later(wait_until: user_trial.trial_end)
        end

        users_preferences_path(is_onboarding:true, redirect_to_valid:true)
      end
    else
      pricing_path(is_onboarding:true, go_to_law: params[:go_to_law], go_to_checkout: params[:go_to_checkout], user_just_registered: true)
    end
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

  def update_mixpanel_user user
    $tracker.people.set(user.id, {
      '$email'            => user.email,
      'first_name'      => user.first_name,
      'last_name'      => user.last_name,
      'phone_number'      => user.phone_number,
      'current_sign_in_at'      => user.current_sign_in_at,
      'last_sign_in_at'      => user.last_sign_in_at,
      'current_sign_in_ip'      => user.current_sign_in_ip,
      'last_sign_in_ip'      => user.last_sign_in_ip,
      'receive_information_emails'      => user.receive_information_emails
    }, ip = user.current_sign_in_ip, {'$ignore_time' => 'true'});
  end


  
end
