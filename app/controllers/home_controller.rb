class HomeController < ApplicationController
  include ActionView::Helpers::NumberHelper
  require 'set'
  
  def index
    @tags = Tag.where(tag_type: TagType.find_by_name("materia"))
  end

  def search_law
    @query = params[:query]
    @laws = findLaws @query
    @stream = findArticles @query
    @result_count = @laws.size
    @articles_count = @stream.size
    @is_search_law = true
    legal_documents = Set[]

    if @query
      if redirectOnEspecialCode @query
        return
      end
    end

    @laws.each do |law|
      legal_documents.add(law.id)
    end
    
    @grouped_laws = []
    @stream.each do |grouped_law|
      law = {count: grouped_law[1].count, law: Law.find_by_id(grouped_law[0]), preview: ("<b>Artículo " + grouped_law[1].first.number + ":</b> ..." + grouped_law[1].first.pg_search_highlight + "...").html_safe, tag_text: ""}
      law[:materia_names] = law[:law].materia_names
      @grouped_laws.push(law)
      @result_count += grouped_law[1].count
      legal_documents.add(grouped_law[0])
    end
    @grouped_laws = @grouped_laws.sort_by{|k|k[:count]}.reverse
    @legal_documents_count = legal_documents.size
    if @result_count == 1
      @result_info_text = number_with_delimiter(@result_count, :delimiter => ',').to_s + ' resultado encontrado'
    else
      @result_info_text = number_with_delimiter(@result_count, :delimiter => ',').to_s + ' resultados encontrados'
    end
    if @legal_documents_count > 1
      @result_info_text += " en " + @legal_documents_count.to_s + " documentos legales."
    elsif @legal_documents_count == 1
      @result_info_text += " en " + @legal_documents_count.to_s + " documento legal."
    end
  end

  def terms_and_conditions
  end

  def pricing
  end
end
