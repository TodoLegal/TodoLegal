class HomeController < ApplicationController
  layout 'onboarding', only: [:pricing, :invite_friends, :send_confirmation_email, :confirm_email_view, :phone_number, :wall]
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper
  require 'set'
  caches_page 
  def index
    #if process_doorkeeper_redirect_to
    #  return
    #end
    # @tags = Tag.where(tag_type: TagType.find_by_name("materia"))
    render action: "index", layout: "landing"
    if current_user
      $tracker.track(current_user.id, 'Site Visit (TL)', { 
        'utm_source' => params[:utm_source],
        'utm_medium' => params[:utm_medium],
        'utm_campaign' => params[:utm_campaign],
        'utm_content' => params[:utm_content],
        'utm_term' => params[:utm_term]
      })
    end
  end

  def home
    @tag_ciadi = Tag.find_by(name: "CIADI")
    @tags = Tag.where(tag_type: TagType.find_by_name("materia"))
    @tag_camaras_de_comercio = Tag.find_by(name: "Cámaras de Comercio")
    expires_in 10.minutes

    if params[:is_free_trial]
      redirect_to "https://valid.todolegal.app", allow_other_host: true
    end

    if current_user
      $tracker.track(current_user.id, 'TodoLegal Session', {
        'user_type' => current_user_type_api(current_user),
        'is_email_confirmed' =>  current_user.confirmed_at?,
        'has_notifications_activated': UsersPreference.find_by(user_id: current_user.id) != nil,
        'session_date' => DateTime.now - 6.hours,
        'location' => "TL Home"
      })

      $tracker.track(current_user.id, 'Site Visit (TL)', { 
        'utm_source' => params[:utm_source],
        'utm_medium' => params[:utm_medium],
        'utm_campaign' => params[:utm_campaign],
        'utm_content' => params[:utm_content],
        'utm_term' => params[:utm_term]
      })
    end
  end

  def token_login
    user = User.find_by authentication_token: params[:authentication_token]
    if user
      sign_in(user)
    end
    respond_to do |format|
      format.html { redirect_to root_path, notice: "Bienvenido " + current_user.first_name + ". Has iniciado sesión." }
    end
    return
  end

  def search_law
    # Retrieve the search query from the request parameters
    @query = params[:query]
  
    # Find laws and articles based on the query with eager loading
    # Force-load to avoid COUNT(*) on relation when calling size
    @laws = findLaws(@query).limit(50).to_a

    # Cache user plan status once to avoid repeated Stripe API calls
    @user_plan_status = current_user ? return_user_plan_status(current_user) : "Basic"
    @user_is_premium = current_user && @user_plan_status != "Basic" && current_user.confirmed_at?
  
    # Initialize result counts
    @result_count = @laws.size
    @is_search_law = true
  
    # Initialize a set to store unique law IDs from current page
    legal_documents = Set.new(@laws.map(&:id))
  
    # Initialize an array to store grouped laws
    @grouped_laws = []
  
    # Tokenize the query into words and non-word characters
    @tokens = @query ? @query.scan(/\w+|\W/) : []
  
    # Special case handling if the query starts with '/'
    if @tokens.first == '/'
      articles_query = []
      law_name_query = ""
  
      # Parse tokens to separate article numbers and law name
      @tokens.each do |token|
        if is_number(token)
          articles_query.push(token)
        elsif token != '/'
          law_name_query = token
        end
      end
  
      # Find articles based on the parsed law name and article numbers using optimized approach
      # First get the matching articles without loading them all into memory
      matching_articles = Article.joins(:law)
                                 .where(laws: { id: Law.search_by_name(law_name_query).select(:id) })
                                 .where(number: articles_query)
      
      # Group them efficiently
      @stream = {}
      matching_articles.find_each do |article|
        @stream[article.law_id] ||= []
        @stream[article.law_id] << article
      end
    else
      # Find articles based on the query
      @stream = findArticles(@query)
    end
  
    # Get the unique law IDs from the articles (clean them to avoid pg_search conflicts)
    law_ids = @stream.keys.map(&:to_i).uniq
  
    # Find laws by their IDs and index them by ID for quick lookup, including eager loading of tags
    laws = Law.where(id: law_ids).includes(law_tags: { tag: :tag_type }).index_by(&:id)
    
    # Preload article counts in a single query to avoid N+1 (use fresh query to avoid pg_search conflicts)
    all_law_ids = ((@laws.map(&:id)) + law_ids).uniq
    @article_counts = Article.where(law_id: all_law_ids)
                            .group(:law_id)
                            .count
  
    # Process each group of articles
    @stream.each do |law_id, articles|
      law = laws[law_id]
      next unless law

      # Generate a preview text for the first article in the group
      preview_text = if @tokens.first == '/'
                       "<b>Artículo #{articles.first.number}</b> #{articles.first.body[0, 300]}..."
                     else
                       "<b>Artículo #{articles.first.number}</b> ...#{customize_highlight(articles.first.pg_search_highlight, @query)}..."
                     end

      # Create a hash to store law data using preloaded materia names
      articles_count = articles.count # Count the articles once 
      law_data = {
        count: articles_count,
        law: law,
        preview: preview_text.html_safe,
        materia_names: law.materia_names, # This now uses preloaded associations
        tag_text: ""
      }

      # Add the law data to the grouped laws array
      @grouped_laws.push(law_data)

      # Update the result count and add the law ID to the set of legal documents
      @result_count += articles_count
      legal_documents.add(law_id)
    end    
    # Sort the grouped laws by the count of articles in descending order
    @grouped_laws.sort_by! { |k| -k[:count] }
    
    # Paginate the sorted grouped laws using Kaminari
    @grouped_laws = Kaminari.paginate_array(@grouped_laws).page(params[:articles_page]).per(6)
  
    # Update the count of unique legal documents
    @legal_documents_count = legal_documents.size
  
    # Generate user-friendly result texts
    @result_info_text = "#{number_with_delimiter(@result_count, delimiter: ',')} resultado#{'s' if @result_count != 1} encontrado#{'s' if @result_count != 1}"
    titles_result = number_with_delimiter(@laws.total_count, delimiter: ',')
    @titles_result_text = "#{titles_result} resultado#{'s' if @laws.total_count != 1}"
    articles_result = number_with_delimiter(@result_count - @laws.total_count, delimiter: ',')
    @articles_result_text = "#{articles_result} resultado#{'s' if @result_count != 1}"
  
    # Track the search activity if a user is logged in
    if current_user
      $tracker.track(current_user.id, 'Site Search', {
        'query' => @query,
        'location' => "Home",
        'location_type' => "Global",
        'results' => titles_result + articles_result
      })
    end
  end

  def pricing
    session[:return_to] = params[:return_to] if params[:return_to]
    @is_onboarding = params[:is_onboarding]
    @pricing_onboarding = params[:pricing_onboarding]
    @go_to_law = params[:go_to_law]
    @activate_pro_account = params[:activate_pro_account]
    @user_just_registered = params[:user_just_registered]
    if session[:return_to]
      @return_to = session[:return_to]
    end
    if current_user
      $tracker.track(current_user.id, 'Pricing Visited', { 
        'utm_source' => params[:utm_source],
        'utm_medium' => params[:utm_medium],
        'utm_campaign' => params[:utm_campaign],
        'utm_content' => params[:utm_content],
        'utm_term' => params[:utm_term]
      })
    else
      @is_onboarding = true
      @pricing_onboarding = true
    end

    if @pricing_onboarding
      @select_basic_plan_path = "/users/sign_up"
    elsif !@go_to_law.blank?
      @select_basic_plan_path = Law.find_by_id(@go_to_law)
    else
      @select_basic_plan_path = root_path
    end

    if @pricing_onboarding
      @select_pro_plan_path = "/users/sign_up"
    else
      @select_pro_plan_path = checkout_path
    end
  end

  def phone_number
    go_to_law = session[:go_to_law]
    go_to_checkout = session[:go_to_checkout]
    is_monthly = session[:is_monthly]
    is_annually = session[:is_annually]

    if request.post?
      new_phone_number = params[:phone_number]
  
      # # Validate the new phone number format
      # unless valid_phone_number?(new_phone_number)
      #   # Handle invalid phone number format
      #   return
      # end
  
      # Update the phone number
      if current_user.update(phone_number: new_phone_number)
        if session[:pricing_onboarding]
          if is_monthly
            redirect_to users_preferences_path(is_onboarding:true, go_to_law: go_to_law, is_monthly: is_monthly)
          elsif is_annually
            redirect_to users_preferences_path(is_onboarding:true, go_to_law: go_to_law, is_annually: is_annually)
          else
            redirect_to users_preferences_path(is_onboarding:true, redirect_to_valid:true)
          end
        else
          redirect_to pricing_path(is_onboarding:true, go_to_law: go_to_law, go_to_checkout: go_to_checkout, user_just_registered: true)
        end
      else
        format.html { render :phone_number }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  def confirm_email_view
  end

  def wall
    if current_user 
      if current_user.confirmed_at && return_user_plan_status(current_user) == "Basic"
        $tracker.track(current_user.id, 'Wall Ver Planes TodoLegal', {
          'user_type' => return_user_plan_status(current_user),
        })
      end
    else
      $tracker.track('', 'Wall Crear Cuenta TodoLegal', {
          'user_type' => 'Anonymous',
        })
    end
  end
  
  def invite_friends
  end

  def send_confirmation_email
    @url = "https#{request.original_url[4...-1]}"
    session[:return_to] = @url
    if current_user && current_user.confirmed_at == nil
      current_user.send_confirmation_instructions
      #redirect_to @url, notice: "Confirmación enviada a tu correo."
      if params[:redirect_to]
        @valid_url = params[:redirect_to]
        redirect_to "#{@valid_url}?confirmation_email_sent", allow_other_host: true
        flash[:notice] = "Confirmación enviada a tu correo."
      else
        redirect_back(fallback_location: @url)
        flash[:notice] = "Confirmación enviada a tu correo."
      end
    else
      redirect_to @url, notice: "Cuenta ya ha sido confirmada.", allow_other_host: true
    end
  end

  def getGoogleDriveFiles file_path, get_parent_files, folder, query
    files = []
    if File.file?(file_path)
      google_drive_data = File.read(file_path)
      if query && query!=""
        files = get_files_like_name(JSON.parse(google_drive_data)["data"], query).sort_by { |v| v["name"] }
      elsif folder && folder!=""
        if get_parent_files
          folder.replace(get_parrent_folder_name JSON.parse(google_drive_data)["data"], folder)
        end
        if folder == ""
          files = JSON.parse(google_drive_data)["data"].sort_by { |v| v["name"] }
        else
          files = get_folder_files JSON.parse(google_drive_data)["data"], folder
        end
      else
        files = JSON.parse(google_drive_data)["data"].sort_by { |v| v["name"] }
      end
    end
    return files
  end

  def google_drive_search
    @query = sanitize_gaceta_query params[:query]
    @folder = params[:folder]
    @get_parent_files = params[:get_parent_files] == 'true'
    @files = getGoogleDriveFiles 'public/google_drive_data.json', @get_parent_files, @folder, @query
  end

  def google_drive_covid_search
    @query = params[:query]
    @folder = params[:folder]
    @get_parent_files = params[:get_parent_files] == 'true'
    @files = getGoogleDriveFiles 'public/google_drive_covid_data.json', @get_parent_files, @folder, @query
  end

  def refer
    if !current_user
      respond_to do |format|
        format.html { redirect_to root_path }
      end
      return
    end
    if ENV['GMAIL_USERNAME']
      if !params["email1"].blank?
        SubscriptionsMailer.refer(current_user, params["email1"]).deliver
      end
      if !params["email2"].blank?
        SubscriptionsMailer.refer(current_user, params["email2"]).deliver
      end
    end

    respond_to do |format|
      format.html { redirect_to root_path, notice: I18n.t(:referal_sent) }
    end
  end

  def crash_tester
  end

  def customize_highlight(text, search_query)
    highlighted_text = text.gsub(/(#{Regexp.escape(search_query)})/i, "<span style='background-color: yellow;'>\\1</span>")
    highlighted_text.html_safe
  end  

protected
  def get_folder_files google_drive_data, folder_name
    google_drive_data.each do |file|
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

  def get_parrent_folder_name google_drive_data, folder_name
    google_drive_data.each do |file|
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

  def sanitize_gaceta_query original_query
    if params[:query].blank?
      return nil
    end
    result_query = ""
    original_query.split.each do |query_word|
      if query_word.length == 5 && query_word.scan(/\D/).empty?
        query_word.insert(2, ',')
      end
      if result_query == ""
        result_query += query_word
      else
        result_query += ' ' + query_word
      end
    end
    return result_query
  end
end
