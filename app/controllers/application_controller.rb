class ApplicationController < ActionController::Base
  include Devise::Controllers::Rememberable
  include ApplicationHelper

  require 'csv'
  # before_action :already_logged_in
  protect_from_forgery with: :null_session
  before_action :configure_devise_permitted_parameters, if: :devise_controller?
  before_action :miniprofiler
  before_action :set_newrelic_user_context
  
  #acts_as_token_authentication_handler_for User, if: :json_request?
  skip_before_action :configure_devise_permitted_parameters, if: :json_request?

  def process_doorkeeper_redirect_to
    if session[:return_to]
      respond_to do |format|
        return_to_path = session[:return_to]
        session[:return_to] = nil
        format.html { redirect_to return_to_path, allow_other_host: true }
      end
      return true
    end
    return false
  end


  def after_sign_in_remember_me(resource)
    remember_me resource
  end
  
  def current_user_is_admin
    current_user != nil && current_user.permissions.find_by_name("Admin") != nil
  end

  def current_user_is_editor
    current_user != nil && (current_user.permissions.find_by_name("Editor") != nil || current_user.permissions.find_by_name("Admin") != nil)
  end

  def current_user_is_editor_tl
    current_user && (current_user.permissions.find_by_name("Editor TL") || current_user.permissions.find_by_name("Editor") || current_user.permissions.find_by_name("Admin"))
  end

  def current_user_plan_is_active customer #TODO: remove duplicated code
    begin
      customer.subscriptions.data.each do |subscription|
        if subscription.plan.product == STRIPE_SUBSCRIPTION_PRODUCT and subscription.plan.active
          return true
        end
      end
    rescue
      return false
    end
    return false
  end

  def user_is_pro user
    if !user
      return false
    end
    if !user.stripe_customer_id.blank?
      customer = Stripe::Customer.retrieve(user.stripe_customer_id)
      if current_user_plan_is_active customer
        return true
      end
    elsif user.permissions.find_by_name("Pro") != nil
      return true
    end
    return false
  end

  def authenticate_admin!
    if !current_user_is_admin
      redirect_to "/?error=Invalid+permissions"
    end
  end

  def authenticate_editor!
    if !current_user_is_editor
      redirect_to "/?error=Invalid+permissions"
    end
  end

  def authenticate_editor_tl!
    if !current_user_is_editor_tl
      redirect_to "/?error=Invalid+permissions"
    end
  end

  def authenticate_pro!
    if user_is_pro current_user
      redirect_to "/?error=Invalid+permissions"
    end
  end

  def redirectOnSpecialCode query
    @tokens = @query.scan(/\w+|\W/)
    if @tokens.first == '/'
      redirect_to search_law_path + "?query=" + @query
    end
    return false
  end

  def is_number string
    string.match(/^(\d)+$/)
  end

  def get_raw_law
    @stream = []
    @highlight_enabled = false
    @query = ""
    @articles_count = 0
    @has_articles_only = true
    @info_is_searched = false

    if params[:query]
      @tokens = params[:query].scan(/\w+|\W/)
      if @tokens.first == '/'
        articles = []
        @tokens.each do |token|
          if is_number token
            articles.push(token)
          end
        end
        params[:articles] = articles
        params[:query] = nil
      end
    end

    if params[:query] && params[:query] != ""
      @highlight_enabled = true
      @query = params[:query]
      @stream = @law.articles.search_by_body_highlighted(params[:query]).with_pg_search_highlight.order(:position).sort_by { |article| article.position }
      @info_is_searched  = true
      @articles_count = @stream.size
    else
      @books = @law.books.order(:position)
      @titles = @law.titles.order(:position)
      @chapters = @law.chapters.order(:position)
      @sections = @law.sections.order(:position)
      @subsections = @law.subsections.order(:position)
      @articles = @law.articles.order(:position)

      @articles_count = @law.cached_articles_count

      go_to_position = nil

      if params[:articles] && params[:articles].size != 1
        @stream = @articles.where(number: params[:articles])
      else
        if params[:articles] && params[:articles].size == 1
          article = @articles.where('number LIKE ?', "%#{params[:articles].first}%").first
          if article
            go_to_position = @articles.where('number LIKE ?', "%#{params[:articles].first}%").first.position
          end
        end

        get_law_stream_return_values = get_law_stream @law, @books, @chapters, @sections, @subsections, @articles, @titles, go_to_position

        @stream = get_law_stream_return_values[0]
        @result_index_items = get_law_stream_return_values[1]
        @go_to_article = get_law_stream_return_values[2]
        @has_articles_only = get_law_stream_return_values[3]
      end
    end

    if current_user && !@query.blank?
      if @stream
        results = @stream.count
      end
      $tracker.track(current_user.id, 'Site Search', {
        'query' => @query,
        'location' => @law.name,
        'location_type' => "Law",
        'results' => results
      })
    end

    @user_can_edit_law = current_user_is_editor_tl
    @user_can_access_law = user_can_access_law @law, current_user
    if !@user_can_access_law
      @stream = @stream.take(5)
    end
  end

  def get_law_stream law, books, chapters, sections, subsections, articles, titles, go_to_position
    stream_size = law.cached_books_count + law.cached_titles_count + law.cached_chapters_count + law.cached_sections_count + law.cached_subsections_count + law.cached_articles_count
    result_stream = []
    result_index_items = []
    result_go_to_article = nil
    result_has_articles_only = false
    book_iterator = 0
    title_iterator = 0
    chapter_iterator = 0
    section_iterator = 0
    subsection_iterator = 0
    article_iterator = 0
    i = 0
    while i < stream_size
      if book_iterator < law.cached_books_count &&
          (law.cached_titles_count == 0 ||
          (title_iterator < law.cached_titles_count && books[book_iterator].position < titles[title_iterator].position)) &&
          (law.cached_chapters_count == 0 ||
          (chapter_iterator < law.cached_chapters_count && books[book_iterator].position < chapters[chapter_iterator].position)) &&
          (law.cached_sections_count == 0 ||
          (section_iterator < law.cached_sections_count && books[book_iterator].position < sections[section_iterator].position)) &&
          (law.cached_subsections_count == 0 ||
          (subsection_iterator < law.cached_subsections_count && books[book_iterator].position < subsections[subsection_iterator].position)) &&
          (law.cached_articles_count == 0 ||
          (article_iterator < law.cached_articles_count && books[book_iterator].position < articles[article_iterator].position))
        result_stream.push books[book_iterator]
        result_index_items.push books[book_iterator]
        book_iterator+=1
      elsif title_iterator < law.cached_titles_count &&
          (law.cached_chapters_count == 0 ||
          (chapter_iterator < law.cached_chapters_count && titles[title_iterator].position < chapters[chapter_iterator].position)) &&
          (law.cached_sections_count == 0 ||
          (section_iterator < law.cached_sections_count && titles[title_iterator].position < sections[section_iterator].position)) &&
          (law.cached_subsections_count == 0 ||
          (subsection_iterator < law.cached_subsections_count && titles[title_iterator].position < subsections[subsection_iterator].position)) &&
          (law.cached_articles_count == 0 ||
          (article_iterator < law.cached_articles_count && titles[title_iterator].position < articles[article_iterator].position))
        result_stream.push titles[title_iterator]
        result_index_items.push titles[title_iterator]
        title_iterator+=1
      elsif chapter_iterator < law.cached_chapters_count &&
          (law.cached_sections_count == 0 ||
          (section_iterator < law.cached_sections_count && chapters[chapter_iterator].position < sections[section_iterator].position)) &&
          (law.cached_subsections_count == 0 ||
          (subsection_iterator < law.cached_subsections_count && chapters[chapter_iterator].position < subsections[subsection_iterator].position)) &&
          (law.cached_articles_count == 0 ||
          (article_iterator < law.cached_articles_count && chapters[chapter_iterator].position < articles[article_iterator].position))
        result_stream.push chapters[chapter_iterator]
        result_index_items.push chapters[chapter_iterator]
        chapter_iterator+=1
      elsif section_iterator < law.cached_sections_count &&
          (law.cached_subsections_count == 0 ||
          (subsection_iterator < law.cached_subsections_count && sections[section_iterator].position < subsections[subsection_iterator].position)) &&
          (law.cached_articles_count == 0 ||
          (article_iterator < law.cached_articles_count && sections[section_iterator].position < articles[article_iterator].position))
        result_stream.push sections[section_iterator]
        result_index_items.push sections[section_iterator]
        section_iterator+=1
      elsif subsection_iterator < law.cached_subsections_count &&
          (law.cached_articles_count == 0 ||
          (article_iterator < law.cached_articles_count && subsections[subsection_iterator].position < articles[article_iterator].position))
        result_stream.push subsections[subsection_iterator]
        result_index_items.push subsections[subsection_iterator]
        subsection_iterator+=1
      else
        result_stream.push articles[article_iterator]
        if go_to_position && articles[article_iterator] && go_to_position == articles[article_iterator].position
          result_go_to_article = article_iterator
        end
        article_iterator+=1
      end
      i+=1
    end
    result_has_articles_only = book_iterator == 0 && title_iterator == 0 && chapter_iterator == 0 && subsection_iterator == 0 && section_iterator == 0
    return result_stream, result_index_items, result_go_to_article, result_has_articles_only
  end
  
  def set_newrelic_user_context
    if current_user
      user_id = current_user.id
      # Set the user context in New Relic
      NewRelic::Agent.add_custom_attributes(user_id: user_id)
    end
  end

# Redirects to the external URL
def external_redirect
  redirect_to params[:url], allow_other_host: true
end

protected

  def clean_session
    session[:pricing_onboarding] = nil
    session[:is_onboarding] = nil
    session[:go_to_checkout] = nil
    session[:go_to_law] = nil
    session[:is_monthly] = nil
    session[:is_annually] = nil
  end

  def after_sign_up_do
    if current_user
      update_mixpanel_user current_user
      $tracker.track(current_user.id, 'Sign Up', {
      '$email'            => current_user.email,
      'first_name'      => current_user.first_name,
      'last_name'      => current_user.last_name,
      'phone_number'    => current_user.phone_number,
      'current_sign_in_at'      => current_user.current_sign_in_at,
      'last_sign_in_at'      => current_user.last_sign_in_at,
      'current_sign_in_ip'      => current_user.current_sign_in_ip,
      'last_sign_in_ip'      => current_user.last_sign_in_ip,
      'receive_information_emails'      => current_user.receive_information_emails
      })

      if ENV['MAILGUN_KEY']
        current_user.send_confirmation_instructions
      end
    end
    
    if $discord_bot
      $discord_bot.send_message($discord_bot_channel_notifications, "Se ha registrado un nuevo usuario a traves de #{current_user.provider} :tada:")
    end


    session[:user_just_signed_up] = true
    go_to_law = session[:go_to_law]
    go_to_checkout = session[:go_to_checkout]
    is_monthly = session[:is_monthly]
    is_annually = session[:is_annually]
    if session[:pricing_onboarding]
      #TODO 
      #Otro if igual al primero con un && is_student y que dentro del envie is_student de param en lugar de is_monthly
      clean_session
      if is_monthly
        user_trial = UserTrial.create(user_id: current_user.id, trial_start: DateTime.now, trial_end: DateTime.now + 2.weeks, active: false)
        users_preferences_path(is_onboarding:true, go_to_law: go_to_law, is_monthly: is_monthly)
      elsif is_annually
        user_trial = UserTrial.create(user_id: current_user.id, trial_start: DateTime.now, trial_end: DateTime.now + 2.weeks, active: false)
        users_preferences_path(is_onboarding:true, go_to_law: go_to_law, is_annually: is_annually)
      else
        #When user chooses Prueba Gratis
        user_trial = UserTrial.create(user_id: current_user.id, trial_start: DateTime.now, trial_end: DateTime.now + 2.weeks, active: true)
        if ENV['MAILGUN_KEY']
          # SubscriptionsMailer.welcome_basic_user(current_user).deliver
          # SubscriptionsMailer.free_trial_end(current_user).deliver_later(wait_until: user_trial.trial_end - 1.days)
          # NotificationsMailer.cancel_notifications(current_user).deliver_later(wait_until: user_trial.trial_end)
        end
        users_preferences_path(is_onboarding:true, redirect_to_valid:true)
      end
    else
      clean_session
      pricing_path(is_onboarding:true, go_to_law: go_to_law, go_to_checkout: go_to_checkout, user_just_registered: true)
    end
  end

  def after_sign_in_path_for(resource)
    
    #TODO: add condition to check is user is in onboarding
    if session[:pricing_onboarding].present?
      after_sign_up_do
    elsif session[:return_to].present?
      return_to_path = session[:return_to]
      session[:return_to] = nil
      external_redirect_path(url: return_to_path)
    else
      signed_in_path
    end
  end

  def after_sign_out_path_for(resource)
    signed_out_path
  end

  def after_confirmation_path_for(resource_name, resource)
    # Customize the redirect URL here
    puts "Uses customized method in application_controller"
    "https://valid.todolegal.app"
  end

  def findLaws query
    @laws = Law.all.search_by_name(query).with_pg_search_highlight
  end

  def findArticles query
    Article.search_by_body_trimmed(query).with_pg_search_highlight.group_by(&:law_id)
  end

  def configure_devise_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:first_name, :last_name, :occupation, :email, :phone_number, :password, :password_confirmation)}
    devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:first_name, :last_name, :occupation, :email, :phone_number, :stripe_customer_id, :password, :current_password)}
  end

  def miniprofiler
    Rack::MiniProfiler.authorize_request if current_user_is_admin
  end

  def json_request?
    request.format.json?
  end

  def user_can_access_law law, user
    law_access = law.law_access
    if law_access
      if law_access.name == "Pro"
        if !user_is_pro user
          return false
        end
      end
      if law_access.name == "Básica"
        if !current_user
          return false
        end
      end
    end
    return true
  end

  def isWordInText word, text
    return /[^a-zA-Z0-9]#{word}[^a-zA-Z0-9]/.match(text)
  end

  def already_logged_in
    Warden::Manager.after_set_user only: :fetch do |record, warden, options|
      scope = options[:scope]
      if record.devise_modules.include?(:session_limitable) &&
        warden.authenticated?(scope) &&
        options[:store] != false
       if record.unique_session_id != warden.session(scope)['unique_session_id'] &&
          !record.skip_session_limitable? && 
          !warden.session(scope)['devise.skip_session_limitable']
         Rails.logger.warn do
           '[devise-security][session_limitable] session id mismatch: '\
           "expected=#{record.unique_session_id.inspect} "\
           "actual=#{warden.session(scope)['unique_session_id'].inspect}"
         end
         warden.raw_session.clear
         warden.logout(scope)
         throw :warden, scope: scope, message: :session_limited
       end
      end
    end
  end
  


end
