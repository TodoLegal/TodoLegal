class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

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
    Article.all.search_by_body(query).group_by(&:law_id)
  end
end
