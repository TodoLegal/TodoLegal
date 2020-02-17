class HomeController < ApplicationController
  include ActionView::Helpers::NumberHelper
  
  def index
    @tags = Tag.where(tag_type: TagType.find_by_name("materia"))
  end

  def search_law
    @query = params[:query]
    @laws = findLaws @query
    @stream = findArticles @query
    @result_count = @laws.size
    @articles_count = @stream.size
    
    @grouped_laws = []
    @stream.each do |grouped_law|
      law = {count: grouped_law[1].count, law: Law.find_by_id(grouped_law[0]), preview: grouped_law[1].first.pg_search_highlight.html_safe}
      @grouped_laws.push(law)
      @result_count += grouped_law[1].count
    end
    @grouped_laws = @grouped_laws.sort_by{|k|k[:count]}.reverse

    if @result_count == 1
      @result_info_text = number_with_delimiter(@result_count, :delimiter => ',').to_s + ' resultado encontrado.'
    else
      @result_info_text = number_with_delimiter(@result_count, :delimiter => ',').to_s + ' resultados encontrados.'
    end
  end

  def terms_and_conditions
  end
end
