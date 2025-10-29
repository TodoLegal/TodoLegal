class ApplicationController < ActionController::Base
  include Devise::Controllers::Rememberable
  include ApplicationHelper

  require 'csv'
  # before_action :already_logged_in
  protect_from_forgery with: :null_session
  before_action :configure_devise_permitted_parameters, if: :devise_controller?
  before_action :miniprofiler
  before_action :set_newrelic_user_context
  
  #acts_as_token_authentication_handler_for User, if: :json_request?
  skip_before_action :configure_devise_permitted_parameters, if: :json_request?

  def process_doorkeeper_redirect_to
    if session[:return_to]
      respond_to do |format|
        return_to_path = session[:return_to]
        session[:return_to] = nil
        format.html { redirect_to return_to_path, allow_other_host: true }
      end
      return true
    end
    return false
  end


  def after_sign_in_remember_me(resource)
    remember_me resource
  end
  
  def current_user_is_admin
    current_user != nil && current_user.permissions.find_by_name("Admin") != nil
  end

  def current_user_is_editor
    current_user != nil && (current_user.permissions.find_by_name("Editor") != nil || current_user.permissions.find_by_name("Admin") != nil)
  end

  def current_user_is_editor_tl
    current_user && (current_user.permissions.find_by_name("Editor TL") || current_user.permissions.find_by_name("Editor") || current_user.permissions.find_by_name("Admin"))
  end

  def user_is_pro user
    if !user
      return false
    end
    if !user.stripe_customer_id.blank?
      customer = Stripe::Customer.retrieve(user.stripe_customer_id)
      if current_user_plan_is_active customer
        return true
      end
    elsif user.permissions.find_by_name("Pro") != nil || user.permissions.find_by_name("Admin") != nil
      return true
    end
    return false
  end

  def authenticate_admin!
    if !current_user_is_admin
      redirect_to "/?error=Invalid+permissions"
    end
  end

  def authenticate_editor!
    if !current_user_is_editor
      redirect_to "/?error=Invalid+permissions"
    end
  end

  def authenticate_editor_tl!
    if !current_user_is_editor_tl
      redirect_to "/?error=Invalid+permissions"
    end
  end

  def authenticate_pro!
    if user_is_pro current_user
      redirect_to "/?error=Invalid+permissions"
    end
  end

  def redirectOnSpecialCode query
    @tokens = @query.scan(/\w+|\W/)
    if @tokens.first == '/'
      redirect_to search_law_path + "?query=" + @query
    end
    return false
  end

  def get_raw_law
    # Use the new LawDisplayService for better performance and maintainability
    result = LawDisplayService.call(@law, user: current_user, params: params)
    
    if result.failure?
      # Log error and fall back to basic display
      Rails.logger.error "LawDisplayService failed: #{result.error_message}"
      @stream = []
      @highlight_enabled = false
      @query = ""
      @articles_count = 0
      @has_articles_only = true
      @info_is_searched = false
      @result_index_items = []
      @go_to_article = nil
      @user_can_edit_law = false
      @user_can_access_law = false
      return
    end
    
    # Extract data from service result
    display_data = result.data
    
    # Set instance variables for backward compatibility with existing views
    @stream = display_data[:stream]
    @highlight_enabled = display_data[:highlight_enabled]
    @query = display_data[:query]
    @articles_count = display_data[:articles_count]
    @has_articles_only = display_data[:has_articles_only]
    @info_is_searched = display_data[:info_is_searched]
    @result_index_items = display_data[:result_index_items]
    @go_to_article = display_data[:go_to_article]
    
    # Set user permissions using existing helper methods
    @user_can_edit_law = current_user_is_editor_tl
    @user_can_access_law = user_can_access_law(@law, current_user)
    
    # Apply access limitations if user cannot access full law
    # The service handles basic limitations, but we need to respect law-specific access rules
    if !@user_can_access_law && @stream.respond_to?(:take)
      @stream = @stream.take(5)
    end
  end

  # DEPRECATED: This method has been replaced by LawStreamBuilder service
  # Keeping for reference during Phase 1 migration - to be removed in Phase 2
  # def get_law_stream law, books, chapters, sections, subsections, articles, titles, go_to_position
  #   # This complex logic has been moved to LawStreamBuilder for better maintainability
  #   # and testability. The new service approach provides the same functionality
  #   # with improved performance through chunked loading strategies.
  # end
  
  def set_newrelic_user_context
    if current_user
      user_id = current_user.id
      # Set the user context in New Relic
      NewRelic::Agent.add_custom_attributes(user_id: user_id)
    end
  end

# Redirects to the external URL
def external_redirect
  redirect_to params[:url], allow_other_host: true
end

protected

  #this after sign up flow (method) is just for third party authentication (google, microsoft, etc)
  def after_sign_up_do
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
      $discord_bot.send_message($discord_bot_channel_notifications, "Se ha registrado un nuevo usuario a traves de #{current_user.provider} :tada:")
    end


    session[:user_just_signed_up] = true
    go_to_law = session[:go_to_law]
    go_to_checkout = session[:go_to_checkout]
    is_monthly = session[:is_monthly]
    is_annually = session[:is_annually]
    if session[:pricing_onboarding]
      #TODO 
      #Otro if igual al primero con un && is_student y que dentro del envie is_student de param en lugar de is_monthly
      # clean_session
      if is_monthly
        user_trial = UserTrial.create(user_id: current_user.id, trial_start: DateTime.now, trial_end: DateTime.now + 2.weeks, active: false)
        phone_number_view_path(is_onboarding:true, go_to_law: go_to_law, is_monthly: is_monthly)
      elsif is_annually
        user_trial = UserTrial.create(user_id: current_user.id, trial_start: DateTime.now, trial_end: DateTime.now + 2.weeks, active: false)
        phone_number_view_path(is_onboarding:true, go_to_law: go_to_law, is_annually: is_annually)
      else
        #When user chooses Prueba Gratis
        user_trial = UserTrial.create(user_id: current_user.id, trial_start: DateTime.now, trial_end: DateTime.now + 2.weeks, active: true)
        if ENV['MAILGUN_KEY']
          SubscriptionsMailer.welcome_basic_user(current_user).deliver
          SubscriptionsMailer.free_trial_end(current_user).deliver_later(wait_until: user_trial.trial_end - 1.days)
          NotificationsMailer.cancel_notifications(current_user).deliver_later(wait_until: user_trial.trial_end)
        end
        phone_number_view_path(is_onboarding:true, redirect_to_valid:true)
      end
    else
      # clean_session
      pricing_path(is_onboarding:true, go_to_law: go_to_law, go_to_checkout: go_to_checkout, user_just_registered: true)
    end
  end

  def after_sign_in_path_for(resource)
    
    #checks if user is in onboarding
    if session[:pricing_onboarding].present?
      after_sign_up_do
    elsif session[:return_to].present?
      return_to_path = session[:return_to]
      session[:return_to] = nil
      external_redirect_path(url: return_to_path)
    else
      signed_in_path
    end
  end

  def after_sign_out_path_for(resource)
    signed_out_path
  end

  def after_confirmation_path_for(resource_name, resource)
    # Customize the redirect URL here
    puts "Uses customized method in application_controller"
    "https://valid.todolegal.app"
  end

  def findLaws query
   Law.search_by_name(query)
      .with_tags
      .select(:id, :name, :creation_number, :status)
  end

  def findArticles query
    return {} if query.blank?

   matching_articles = Article.search_by_body_trimmed(query)
                          .select(:id, :law_id, :number, :body)
                          .with_pg_search_highlight
                          .limit(200)
                          .group_by(&:law_id)

    # Limit to 20 articles per law for performance
    matching_articles.transform_values { |articles| articles.take(20) }
  end

  def configure_devise_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:first_name, :last_name, :occupation, :email, :phone_number, :password, :password_confirmation)}
    devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:first_name, :last_name, :occupation, :email, :phone_number, :stripe_customer_id, :password, :current_password)}
  end

  def miniprofiler
    Rack::MiniProfiler.authorize_request if current_user_is_admin
  end

  def json_request?
    request.format.json?
  end

  def user_can_access_law law, user
    law_access = law.law_access
    if law_access
      if law_access.name == "Pro"
        if !user_is_pro user
          return false
        end
      end
      if law_access.name == "Básica"
        if !current_user
          return false
        end
      end
    end
    return true
  end
  
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
         warden.raw_session.clear
         warden.logout(scope)
         throw :warden, scope: scope, message: :session_limited
       end
      end
    end
  end
  


end
