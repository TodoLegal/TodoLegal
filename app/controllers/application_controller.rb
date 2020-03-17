class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

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
end
