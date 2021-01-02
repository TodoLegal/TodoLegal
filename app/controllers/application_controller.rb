class ApplicationController < ActionController::Base
  include Devise::Controllers::Rememberable
  require 'csv'

  protect_from_forgery with: :null_session
  before_action :configure_devise_permitted_parameters, if: :devise_controller?
  before_action :miniprofiler
  #acts_as_token_authentication_handler_for User, if: :json_request?
  skip_before_action :configure_devise_permitted_parameters, if: :json_request?

  def after_sign_in_remember_me(resource)
    remember_me resource
  end
  
  def current_user_is_admin
    current_user != nil && current_user.permissions.find_by_name("Admin") != nil
  end

  def current_user_is_editor
    current_user != nil && (current_user.permissions.find_by_name("Editor") != nil || current_user.permissions.find_by_name("Admin") != nil)
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

  def current_user_plan_is_active customer
    begin
      customer.subscriptions.data.each do |subscription|
        if subscription.plan.product == STRIPE_SUBSCRIPTION_PRODUCT and subscription.plan.active
          return true
        end
      end
    rescue
      puts "Todo: Handle Stripe customer error"
    end
    return false
  end

  def get_raw_law
    @stream = []
    @index_items = []
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
      i = 0
      book_iterator = 0
      title_iterator = 0
      chapter_iterator = 0
      section_iterator = 0
      subsection_iterator = 0
      article_iterator = 0

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

        stream_size = @law.cached_books_count + @law.cached_titles_count + @law.cached_chapters_count + @law.cached_sections_count + @law.cached_subsections_count + @law.cached_articles_count
        while i < stream_size
          if book_iterator < @law.cached_books_count &&
              (@law.cached_titles_count == 0 ||
              (title_iterator < @law.cached_titles_count && @books[book_iterator].position < @titles[title_iterator].position)) &&
              (@law.cached_chapters_count == 0 ||
              (chapter_iterator < @law.cached_chapters_count && @books[book_iterator].position < @chapters[chapter_iterator].position)) &&
              (@law.cached_sections_count == 0 ||
              (section_iterator < @law.cached_sections_count && @books[book_iterator].position < @sections[section_iterator].position)) &&
              (@law.cached_subsections_count == 0 ||
              (subsection_iterator < @law.cached_subsections_count && @books[book_iterator].position < @subsections[subsection_iterator].position)) &&
              (@law.cached_articles_count == 0 ||
              (article_iterator < @law.cached_articles_count && @books[book_iterator].position < @articles[article_iterator].position))
            @stream.push @books[book_iterator]
            @index_items.push @books[book_iterator]
            book_iterator+=1
          elsif title_iterator < @law.cached_titles_count &&
              (@law.cached_chapters_count == 0 ||
              (chapter_iterator < @law.cached_chapters_count && @titles[title_iterator].position < @chapters[chapter_iterator].position)) &&
              (@law.cached_sections_count == 0 ||
              (section_iterator < @law.cached_sections_count && @titles[title_iterator].position < @sections[section_iterator].position)) &&
              (@law.cached_subsections_count == 0 ||
              (subsection_iterator < @law.cached_subsections_count && @titles[title_iterator].position < @subsections[subsection_iterator].position)) &&
              (@law.cached_articles_count == 0 ||
              (article_iterator < @law.cached_articles_count && @titles[title_iterator].position < @articles[article_iterator].position))
            @stream.push @titles[title_iterator]
            @index_items.push @titles[title_iterator]
            title_iterator+=1
          elsif chapter_iterator < @law.cached_chapters_count &&
              (@law.cached_sections_count == 0 ||
              (section_iterator < @law.cached_sections_count && @chapters[chapter_iterator].position < @sections[section_iterator].position)) &&
              (@law.cached_subsections_count == 0 ||
              (subsection_iterator < @law.cached_subsections_count && @chapters[chapter_iterator].position < @subsections[subsection_iterator].position)) &&
              (@law.cached_articles_count == 0 ||
              (article_iterator < @law.cached_articles_count && @chapters[chapter_iterator].position < @articles[article_iterator].position))
            @stream.push @chapters[chapter_iterator]
            @index_items.push @chapters[chapter_iterator]
            chapter_iterator+=1
          elsif section_iterator < @law.cached_sections_count &&
              (@law.cached_subsections_count == 0 ||
              (subsection_iterator < @law.cached_subsections_count && @sections[section_iterator].position < @subsections[subsection_iterator].position)) &&
              (@law.cached_articles_count == 0 ||
              (article_iterator < @law.cached_articles_count && @sections[section_iterator].position < @articles[article_iterator].position))
            @stream.push @sections[section_iterator]
            @index_items.push @sections[section_iterator]
            section_iterator+=1
          elsif subsection_iterator < @law.cached_subsections_count &&
              (@law.cached_articles_count == 0 ||
              (article_iterator < @law.cached_articles_count && @subsections[subsection_iterator].position < @articles[article_iterator].position))
            @stream.push @subsections[subsection_iterator]
            @index_items.push @subsections[subsection_iterator]
            subsection_iterator+=1
          else
            @stream.push @articles[article_iterator]
            if go_to_position && @articles[article_iterator] && go_to_position == @articles[article_iterator].position
              @go_to_article = article_iterator
            end
            article_iterator+=1
          end
          i+=1
        end
      end

      @has_articles_only = book_iterator == 0 && title_iterator == 0 && chapter_iterator == 0 && subsection_iterator == 0 && section_iterator == 0
    end

    @user_can_edit_law = current_user_is_editor
    @user_can_access_law = user_can_access_law @law, current_user
    if !@user_can_access_law
      @stream = @stream.take(5)
    end
  end
  
protected
  
  def after_sign_in_path_for(resource)
    signed_in_path
  end

  def after_sign_out_path_for(resource)
    signed_out_path
  end

  def findLaws query
    @laws = Law.all.search_by_name(query).with_pg_search_highlight
  end

  def findArticles query
    Article.search_by_body_trimmed(query).with_pg_search_highlight.group_by(&:law_id)
  end

  def configure_devise_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:first_name, :last_name, :occupation, :receive_information_emails, :is_contributor, :email, :password, :password_confirmation)}
    devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:first_name, :last_name, :occupation, :receive_information_emails, :is_contributor, :email, :stripe_customer_id, :password, :current_password)}
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
end
