class HomeController < ApplicationController
  include ActionView::Helpers::NumberHelper
  require 'set'
  
  def index
    @tags = Tag.where(tag_type: TagType.find_by_name("materia"))

    file = File.read('public/covid_drive_data.json')
    data_hash = JSON.parse(file)
    @covid_files_count = data_hash['file_count']
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

  require "google/apis/drive_v3"
  require "googleauth"
  require "googleauth/stores/file_token_store"
  require "fileutils"
  OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
  APPLICATION_NAME = "Drive API Ruby Quickstart".freeze
  CREDENTIALS_PATH = "/root/credentials.json".freeze
  TOKEN_PATH = "token.yaml".freeze
  SCOPE = Google::Apis::DriveV3::AUTH_DRIVE_METADATA_READONLY

  def authorize
    client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
    token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
    authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
    user_id = "default"
    credentials = authorizer.get_credentials user_id
    if credentials.nil?
      url = authorizer.get_authorization_url base_url: OOB_URI
      puts "Open the following URL in the browser and enter the " \
           "resulting code after authorization:\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    credentials
  end

  def drive_search
    @query = params[:query]
    @files = []

    drive_service = Google::Apis::DriveV3::DriveService.new
    drive_service.client_options.application_name = APPLICATION_NAME
    drive_service.authorization = authorize

    if @query
      response = drive_service.list_files(page_size: 1000,
                                          q: "'1bD-lkYMih3ct86gRzv4bQU8YBmH8z1vo' in parents and name contains '" + @query + "'",
                                          fields: "files")
    else
      response = drive_service.list_files(page_size: 1000,
                                          q: "'1bD-lkYMih3ct86gRzv4bQU8YBmH8z1vo' in parents",
                                          fields: "files")
    end
    @files = response.files
  end
end
