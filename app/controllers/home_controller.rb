class HomeController < ApplicationController
  def index
    @tags = Tag.where(tag_type: TagType.find_by_name("materia"))
  end

  def search_law
    @query = params[:query]
    @result_count = 0
    @laws = Law.all.search_by_name(@query).with_pg_search_highlight
    
    @result_count += @laws.size

    @stream = Article.all.search_by_body(params[:query]).group_by(&:law_id)
    @articles_count = @stream.size
    
    @grouped_laws = []
    @stream.each do |grouped_law|
      law = {count: grouped_law[1].count, law: Law.find_by_id(grouped_law[0])}
      @grouped_laws.push(law)
      @result_count += grouped_law[1].count
    end
    @grouped_laws = @grouped_laws.sort_by{|k|k[:count]}.reverse
  end

  def terms_and_conditions
  end
end
