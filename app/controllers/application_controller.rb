class ApplicationController < ActionController::Base
  include Devise::Controllers::Rememberable
  require 'csv'

  protect_from_forgery with: :null_session
  before_action :configure_devise_permitted_parameters, if: :devise_controller?
  before_action :miniprofiler

  def after_sign_in_remember_me(resource)
    remember_me resource
  end
  
  def current_user_is_admin
    current_user != nil && current_user.permissions.find_by_name("Admin") != nil
  end

  def current_user_is_editor
    current_user != nil && (current_user.permissions.find_by_name("Editor") != nil || current_user.permissions.find_by_name("Admin") != nil)
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

  def authenticate_editor!
    if !current_user_is_editor
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

  def is_number string
    string.match(/^(\d)+$/)
  end

  def current_user_plan_is_active customer
    begin
      customer.subscriptions.data.each do |subscription|
        if subscription.plan.product == STRIPE_SUBSCRIPTION_PRODUCT and subscription.plan.active
          return true
        end
      end
    rescue
      puts "Todo: Handle Stripe customer error"
    end
    return false
  end
  
protected
  
  def after_sign_in_path_for(resource)
    signed_in_path
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

  def miniprofiler
    Rack::MiniProfiler.authorize_request if current_user_is_admin
  end
end
