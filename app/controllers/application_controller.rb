class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session
  before_action :configure_devise_permitted_parameters, if: :devise_controller?

  def current_user_is_admin
    current_user && current_user.permissions.find_by_name("admin")
  end

  def current_user_is_pro
    current_user && current_user.permissions.find_by_name("pro")
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
  
protected
  def after_sign_up_path_for(resource)
    root_path
  end
  def after_sign_in_path_for(resource)
    root_path
  end

  def findLaws query
    @laws = Law.all.search_by_name(query).with_pg_search_highlight
  end

  def findArticles query
    Article.search_by_body_trimmed(query).with_pg_search_highlight.group_by(&:law_id)
  end

  def configure_devise_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:first_name, :last_name, :occupation, :is_contributor, :email, :password)}
    devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:first_name, :last_name, :occupation, :is_contributor, :email, :password, :current_password)}
  end
end
