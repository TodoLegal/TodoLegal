class HomeController < ApplicationController
  def index
    @tags = Tag.where(tag_type: TagType.find_by_name("materia"))
  end

  def search_law
    @query = params[:query]
    @laws = Law.all.search_by_name(@query).with_pg_search_highlight
  end
end
