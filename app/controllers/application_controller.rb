class ApplicationController < ActionController::Base
  include Devise::Controllers::Rememberable
  require 'csv'

  protect_from_forgery with: :null_session
  before_action :configure_devise_permitted_parameters, if: :devise_controller?

  def after_sign_in_remember_me(resource)
    remember_me resource
  end
  
  def current_user_is_admin
    current_user != nil && current_user.permissions.find_by_name("Admin") != nil
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
    elsif user.permissions.find_by_name("Pro") != nil
      return true
    end
    return false
  end

  def authenticate_admin!
    if !current_user_is_admin
      redirect_to "/?error=Invalid+permissions"
    end
  end

  def authenticate_pro!
    if user_is_pro current_user
      redirect_to "/?error=Invalid+permissions"
    end
  end

  def is_redirect_pending
    session[:redirect_to_law] || session[:user_just_signed_up] || session[:redirect_to_checkout]
  end

  def handle_redirect
    redirect_to_law_id = session[:redirect_to_law]
    user_just_signed_up = session[:user_just_signed_up]
    redirect_to_checkout = session[:redirect_to_checkout]
    session[:redirect_to_law] = nil
    session[:user_just_signed_up] = nil
    session[:redirect_to_checkout] = nil

    if redirect_to_checkout
      respond_to do |format|
        if redirect_to_law_id.blank?
          format.html { redirect_to checkout_path }
        else
          format.html { redirect_to checkout_path + "?go_to_law=" + redirect_to_law_id }
        end
      end
      return
    end

    if redirect_to_law_id
      respond_to do |format|
        format.html { redirect_to Law.find_by_id(redirect_to_law_id) }
      end
    elsif user_just_signed_up
      respond_to do |format|
        format.html { redirect_to signed_up_path }
      end
    end
  end

  def redirectOnSpecialCode query
    @tokens = @query.scan(/\w+|\W/)
    if @tokens.first == '/'
      redirect_to search_law_path + "?query=" + @query
    end
    return false
  end

  def is_number string
    string.match(/^(\d)+$/)
  end

  def current_user_plan_is_active customer
    begin
      customer.subscriptions.data.each do |subscription|
        if subscription.plan.product == STRIPE_PRODUCT and subscription.plan.active
          return true
        end
      end
    rescue
      puts "Todo: Handle Stripe customer error"
    end
    return false
  end

  def cancel_all_subscriptions customer
    customer.subscriptions.data.each do |subscription|
      Stripe::Subscription.update(
        subscription.id,
        {
          cancel_at_period_end: true,
        }
      )
    end
  end
  
protected
  
  def after_sign_in_path_for(resource)
    redirect_to_law_id = session[:redirect_to_law]
    if redirect_to_law_id
      session[:redirect_to_law] = nil
      Law.find_by_id(redirect_to_law_id)
    else
      signed_in_path
    end
  end

  def after_sign_out_path_for(resource)
    signed_out_path
  end

  def findLaws query
    @laws = Law.all.search_by_name(query).with_pg_search_highlight
  end

  def findArticles query
    Article.search_by_body_trimmed(query).with_pg_search_highlight.group_by(&:law_id)
  end

  def configure_devise_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:first_name, :last_name, :occupation, :receive_information_emails, :is_contributor, :email, :password, :password_confirmation)}
    devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:first_name, :last_name, :occupation, :receive_information_emails, :is_contributor, :email, :stripe_customer_id, :password, :current_password)}
  end
end
