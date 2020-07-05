class HomeController < ApplicationController
  layout 'onboarding', only: [:pricing, :invite_friends]
  include ActionView::Helpers::NumberHelper
  require 'set'
  
  def index
    if is_redirect_pending
      handle_redirect
      return
    end

    @tags = Tag.where(tag_type: TagType.find_by_name("materia"))

    covid_drive_data_json_path = 'public/covid_drive_data.json'
    if File.file?(covid_drive_data_json_path)
      file = File.read(covid_drive_data_json_path)
      data_hash = JSON.parse(file)
      @covid_files_count = data_hash['file_count']
    end
  end

  def search_law
    @query = params[:query]
    @laws = findLaws @query
    @stream = findArticles @query
    @result_count = @laws.size
    @articles_count = @stream.size
    @is_search_law = true
    legal_documents = Set[]

    #if @query
    #  if redirectOnSpecialCode @query
    #    return
    #  end
    #end

    @laws.each do |law|
      legal_documents.add(law.id)
    end

    @grouped_laws = []

    @tokens = []
    if @query
      @tokens = @query.scan(/\w+|\W/)
    end

    if @tokens.first == '/'
      articles_query = []
      law_name_query = ""
      @tokens.each do |token|
        if is_number(token)
          articles_query.push(token)
        elsif token != '/'
          law_name_query = token
        end
      end
      @stream = Article.where(law: Law.all.search_by_name(law_name_query)).where(number: articles_query).group_by(&:law_id)
      @stream.each do |grouped_law|
        law = {count: grouped_law[1].count, law: Law.find_by_id(grouped_law[0]), preview: ("<b>Artículo " + grouped_law[1].first.number + "</b> " + grouped_law[1].first.body[0,300] + "...").html_safe}
        law[:materia_names] = law[:law].materia_names
        @grouped_laws.push(law)
        @result_count = @grouped_laws.count
      end
      @grouped_laws = @grouped_laws.sort_by{|k|k[:count]}.reverse
    else
      @stream.each do |grouped_law|
        law = {count: grouped_law[1].count, law: Law.find_by_id(grouped_law[0]), preview: ("<b>Artículo " + grouped_law[1].first.number + "</b> ..." + grouped_law[1].first.pg_search_highlight + "...").html_safe, tag_text: ""}
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
  end

  def terms_and_conditions
  end

  def privacy_policy
  end

  def pricing
  end
  
  def invite_friends
    @is_onboarding = params[:is_onboarding]
  end
  
  def drive_search
    @query = params[:query]
    @folder = params[:folder]
    @get_parent_files = params[:get_parent_files] == 'true'
    @files = []

    if File.file?('public/covid_drive_data.json')
      covid_drive_data = File.read('public/covid_drive_data.json')
      if @query && @query!=""
        @files = get_files_like_name(JSON.parse(covid_drive_data)["data"], @query).sort_by { |v| v["name"] }
      elsif @folder && @folder!=""
        if @get_parent_files
          @folder = get_parrent_folder_name JSON.parse(covid_drive_data)["data"], @folder
        end
        if @folder == ""
          @files = JSON.parse(covid_drive_data)["data"].sort_by { |v| v["name"] }
        else
          @files = get_folder_files JSON.parse(covid_drive_data)["data"], @folder
        end
      else
        @files = JSON.parse(covid_drive_data)["data"].sort_by { |v| v["name"] }
      end
    end
  end

  def refer
    if !current_user
      respond_to do |format|
        format.html { redirect_to root_path }
      end
      return
    end
    if !params["email1"].blank?
      SubscriptionsMailer.refer(current_user, params["email1"]).deliver
    end
    if !params["email2"].blank?
      SubscriptionsMailer.refer(current_user, params["email2"]).deliver
    end
    if is_redirect_pending
      handle_redirect
      return
    else
      respond_to do |format|
        format.html { redirect_to root_path, notice: I18n.t(:referal_sent) }
      end
    end
  end

  def crash_tester
  end

protected
  def get_folder_files covid_drive_data, folder_name
    covid_drive_data.each do |file|
      if file['type'] == 'application/vnd.google-apps.folder'
        if file['name'] == folder_name
          return file['files'].sort_by { |v| v["name"] }
        end
        recursive_result = get_folder_files file['files'], folder_name
        if recursive_result != []
          return recursive_result
        end
      end
    end
    return []
  end

  def get_parrent_folder_name covid_drive_data, folder_name
    covid_drive_data.each do |file|
      if file['type'] == 'application/vnd.google-apps.folder'
        file['files'].each do |sub_file|
          if sub_file['name'] == folder_name
            return file['name']
          end
        end
        recursive_result = get_parrent_folder_name file['files'], folder_name
        if recursive_result != ""
          return recursive_result
        end
      end
    end
    return ""
  end

  def get_files_like_name(files, name)
    result = []
    files.each do |file|
      if file["type"] == "application/vnd.google-apps.folder"
        result += get_files_like_name(file["files"], name)
      elsif file["name"].downcase.include?(name.downcase)
        result.push(file)
      end
    end
    return result
  end
end
