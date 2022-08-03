module ApplicationHelper
  require 'bcrypt'

  def current_user_is_admin
    current_user && current_user.permissions.find_by_name("Admin")
  end

  def current_user_is_editor
    current_user && (current_user.permissions.find_by_name("Editor") || current_user.permissions.find_by_name("Admin"))
  end

  def current_user_is_pro
    current_user && current_user.permissions.find_by_name("Pro")
  end

  def user_is_admin_api user
    user &&  user.permissions.find_by_name("Admin")
  end

  def user_is_editor_api user
    user && ( user.permissions.find_by_name("Editor") ||  user.permissions.find_by_name("Admin"))
  end

  def user_is_pro_api user
    user &&  user.permissions.find_by_name("Pro")
  end

  def is_editor_mode_enabled
    session[:edit_mode_enabled]
  end

  def google_drive_covid_documents_count
    google_drive_covid_data_json_path = 'public/google_drive_covid_data.json'
    google_drive_covid_files_count = 0
    if File.file?(google_drive_covid_data_json_path)
      file = File.read(google_drive_covid_data_json_path)
      data_hash = JSON.parse(file)
      google_drive_covid_files_count =  data_hash['file_count']
    end
    return google_drive_covid_files_count
  end

  def all_document_count
    Law.count + Document.count + google_drive_covid_documents_count
  end

  def get_fingerprint
    raw_fingerprint = request.remote_ip +
      browser.to_s +
      browser.device.name +
      browser.device.id.to_s +
      browser.platform.name
    hashed_fingerprint = BCrypt::Engine.hash_secret( raw_fingerprint, "$2a$10$ThisIsTheSalt22CharsX." )
    return hashed_fingerprint
  end

  def get_user_document_download_tracker(user_id_str)
   fingerprint = get_fingerprint + user_id_str
   user_document_download_tracker = UserDocumentDownloadTracker.find_by_fingerprint(fingerprint)
   if !user_document_download_tracker
     user_document_download_tracker = UserDocumentDownloadTracker.create(fingerprint: fingerprint, downloads: 0, period_start: DateTime.now)
   end
  #  if user_document_download_tracker.period_start <= 1.month.ago # TODO set time window
  #    user_document_download_tracker.period_start = DateTime.now
  #    user_document_download_tracker.downloads = 0
  #    user_document_download_tracker.save
  #  end
   return user_document_download_tracker
  end

  #deprecated
  def can_access_documents(user_document_download_tracker, current_user_type)
   if current_user_type == "pro"
     return true
   elsif current_user_type == "basic"
     return user_document_download_tracker.downloads < MAXIMUM_BASIC_MONTHLY_DOCUMENTS
   else
    #  return user_document_download_tracker.downloads < MAXIMUM_NOT_LOGGGED_MONTHLY_DOCUMENTS
    return false
   end
  end

  def current_user_type user
    if user
      if !user.stripe_customer_id.blank?
        customer = Stripe::Customer.retrieve(user.stripe_customer_id)
      end
      if (customer and current_user_plan_is_active customer) || (current_user_is_editor)
        return "pro"
      else
        return "basic"
      end
    end
    return "not logged"
  end

  def current_user_type_api user
    if user
      if !user.stripe_customer_id.blank?
        customer = Stripe::Customer.retrieve(user.stripe_customer_id)
      end
      if (customer and current_user_plan_is_active customer) || (user_is_editor_api user) || (user_is_pro_api user)
        return "pro"
      else
        return "basic"
      end
    end
    return "not logged"
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

  def ley_abierta_url
    "https://pod.link/LeyAbierta/"
  end

  def non_pro_law_count
    todos_law_count = LawAccess.find_by_name("Todos").laws.count
    basica_law_count = LawAccess.find_by_name("Básica").laws.count
    return todos_law_count + basica_law_count
  end

  def maximum_basic_monthly_documents
    MAXIMUM_BASIC_MONTHLY_DOCUMENTS
  end

  def law_count
    Law.count
  end

  def valid_document_count
    Document.where.not(name: "Gaceta").count
  end

  def valid_gazettes_count
    Document.where.not(publication_number: nil).group_by(&:publication_number).count
  end

  def user_browser_language_is_english
    browser_locale = request.env['HTTP_ACCEPT_LANGUAGE'].try(:scan, /^[a-z]{2}/).try(:first) 
    return browser_locale.eql? "en"
  end

  def get_document_title document
    if !document.name.blank? and !document.issue_id.blank?
      return document.name + ", " + document.issue_id
    elsif !document.name.blank? and document.issue_id.blank?
      return document.name
    elsif document.name.blank? and !document.issue_id.blank?
      return document.issue_id
    else
      return "<vacío>"
    end
  end

  def enqueue_new_job user
    @user_preferences = UsersPreference.find_by(user_id: user.id)
    mail_frequency = @user_preferences.mail_frequency
    job = MailUserPreferencesJob.set(wait: @user_preferences.mail_frequency.days).perform_later(user)
    @user_preferences.job_id = job.provider_job_id
    @user_preferences.save
  end

  def delete_user_notifications_job job_id
    if job_id
      job_to_delete = Sidekiq::ScheduledSet.new.find_job(job_id)
      return job_to_delete ? job_to_delete.delete : false
    end
    return false
  end

  def get_tags_name tags_ids
    tags_names = []

    tags_ids.each do |id|
        tag = Tag.find_by(id: id)
        if tag
            tags_names.push(tag.name)
        end
    end

    return tags_names
  end

  # def already_logged_in_helper
  #   Warden::Manager.after_set_user only: :fetch do |record, warden, options|
  #     scope = options[:scope]
  #     if record.devise_modules.include?(:session_limitable) && warden.authenticated?(scope) && options[:store] != false
  #     #Log Inicio
  #      if record.unique_session_id != warden.session(scope)['unique_session_id'] && !record.skip_session_limitable? &&  !warden.session(scope)['devise.skip_session_limitable']
  #       return true
  #      end
  #     end
  #   end
  #   return false
  # end

  #def send_confirmation_email
  #  current_user.send_confirmation_instructions
  #end

end
