class HomeController < ApplicationController
  include ActionView::Helpers::NumberHelper
  require 'set'
  
  def index
    @tags = Tag.where(tag_type: TagType.find_by_name("materia"))

    covid_drive_data_path = 'public/covid_drive_data.json'
    if File.exist?(covid_drive_data_path)
      file = File.read(covid_drive_data_path)
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

  def drive_search
    @query = params[:query]
    @folder = params[:folder]
    @get_parent_files = params[:get_parent_files] == 'true'
    @files = []

    if @query && @query!=""
      covid_drive_data = File.read('public/covid_drive_data.json')
      @files = get_files_like_name(JSON.parse(covid_drive_data)["data"], @query).sort_by { |v| v["name"] }
    elsif @folder && @folder!=""
      covid_drive_data = File.read('public/covid_drive_data.json')
      if @get_parent_files
        @folder = get_parrent_folder_name JSON.parse(covid_drive_data)["data"], @folder
      end
      if @folder == ""
        covid_drive_data = File.read('public/covid_drive_data.json')
        @files = JSON.parse(covid_drive_data)["data"].sort_by { |v| v["name"] }
      else
        @files = get_folder_files JSON.parse(covid_drive_data)["data"], @folder
      end
    else
      covid_drive_data = File.read('public/covid_drive_data.json')
      @files = JSON.parse(covid_drive_data)["data"].sort_by { |v| v["name"] }
    end
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
