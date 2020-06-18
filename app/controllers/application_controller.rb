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

  def current_user_is_pro
    current_user != nil && current_user.permissions.find_by_name("Pro") != nil
  end

  def authenticate_admin!
    if !current_user_is_admin
      redirect_to "/?error=Invalid+permissions"
    end
  end

  def authenticate_pro!
    if current_user_is_pro
      redirect_to "/?error=Invalid+permissions"
    end
  end

  def is_redirect_pending
    session[:redirect_to_law] || session[:user_just_signed_up]
  end

  def handle_redirect
    redirect_to_law_id = session[:redirect_to_law]
    user_just_signed_up = session[:user_just_signed_up]
    session[:redirect_to_law] = nil
    session[:user_just_signed_up] = nil
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
    devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:first_name, :last_name, :occupation, :receive_information_emails, :is_contributor, :email, :password, :current_password)}
  end
end
