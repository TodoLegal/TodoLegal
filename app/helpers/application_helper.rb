module ApplicationHelper
  require 'bcrypt'

  def current_user_is_admin
    current_user && current_user.permissions.find_by_name("Admin")
  end

  def current_user_is_editor
    current_user && (current_user.permissions.find_by_name("Editor") || current_user.permissions.find_by_name("Admin"))
  end

  def current_user_is_editor_tl
    current_user && (current_user.permissions.find_by_name("Editor TL") || current_user.permissions.find_by_name("Editor") || current_user.permissions.find_by_name("Admin"))
  end

  def current_user_permission
    permission_name = "invalid"
    permission_name = "Editor D2" if current_user.permissions.find_by_name("Editor D2")
    permission_name = "Editor" if current_user_is_editor
    permission_name = "Admin" if current_user_is_admin

    return permission_name
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

  #deprecated
  def get_fingerprint
    raw_fingerprint = request.remote_ip +
      browser.to_s +
      browser.device.name +
      browser.device.id.to_s +
      browser.platform.name
    hashed_fingerprint = BCrypt::Engine.hash_secret( raw_fingerprint, "$2a$10$ThisIsTheSalt22CharsX." )
    return hashed_fingerprint
  end

  #deprecated
  def get_user_document_download_tracker(user_id_str)
   fingerprint = get_fingerprint + user_id_str
   user_document_download_tracker = UserDocumentDownloadTracker.find_by_fingerprint(fingerprint)
   if !user_document_download_tracker
     user_document_download_tracker = UserDocumentDownloadTracker.create(fingerprint: fingerprint, downloads: 0, period_start: DateTime.now)
   end
   return user_document_download_tracker
  end

  def create_preferences(user)
    default_tags_names = ["Tributario", "Reformas", "Aduanas", "Subsidio", "Mercantil", "Congreso Nacional", "Secretaría de Desarrollo Económico"]
    default_tags_id = []
    default_frequency = 1

    default_tags_names.each do | tag_name |
      tag = Tag.find_by(name: tag_name);
      if tag
        default_tags_id.push(tag.id)
      end
    end

    preferences = UsersPreference.create(user_id: user.id, mail_frequency: default_frequency, user_preference_tags: default_tags_id)

    return preferences
  end

  def can_access_documents(user)
    current_user_type = current_user_type_api(user)
    user_trial = nil
    user_preferences = nil
    
    if current_user_type != "not logged"
      user_trial = UserTrial.find_by(user_id: user.id)
      user_preferences = UsersPreference.find_by(user_id: user.id)
    end

    if current_user_type == "pro"
      if !user_trial 
        user_trial = UserTrial.create(user_id: user.id, trial_start: DateTime.now, trial_end: DateTime.now + 2.weeks, active: false)
      end
      if !user_preferences
        user_preferences = create_preferences(user)
        NotificationsMailer.pro_without_active_notifications(user).deliver
        enqueue_new_job(user)
      end
      return true
    elsif current_user_type == "basic"
      if !user_trial
        user_trial = UserTrial.create(user_id: user.id, trial_start: DateTime.now, trial_end: DateTime.now + 2.weeks, active: true)
        NotificationsMailer.basic_with_active_notifications(user).deliver
        SubscriptionsMailer.free_trial_end(user).deliver_later(wait_until: user_trial.trial_end - 1.days)
        NotificationsMailer.cancel_notifications(user).deliver_later(wait_until: user_trial.trial_end)
      end
      if !user_preferences
        user_preferences = create_preferences(user)
        enqueue_new_job(user)
      end
      return user_trial.active?
    else
      return false
    end
  end

  def remaining_free_trial_time user
    user_trial = UserTrial.find_by(user_id: user.id)
    trial_remaining_time = 0
    current_user_type = current_user_type_api(user)

    if current_user_type == "pro"
      return -1
    end

    if user_trial
      trial_remaining_time = user_trial.trial_end - user_trial.trial_start
      trial_remaining_time = (trial_remaining_time/1.day).to_i
    end

    return trial_remaining_time
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
      return false
    end
    return false
  end

  def check_if_user_has_active_stripe_plan user
    stripe_status = "Sin Plan"

    if user.stripe_customer_id
      customer = Stripe::Customer.retrieve(user.stripe_customer_id)
      if current_user_plan_is_active(customer)
        stripe_status = "Activo"
      else
        stripe_status = "Downgraded"
      end
    else user.stripe_customer_id
      stripe_status = "Sin Plan"
    end

    return stripe_status
  end

  def return_user_plan_status user
    todolegal_status = "Free trial"
    user_trial = user.user_trial ? true : false
    todolegal_status = user.user_trial && user.user_trial.active ? todolegal_status : "Free trial end"
    todolegal_status = user.permissions.find_by_name("Editor") ? "Editor" : todolegal_status
    todolegal_status = user.permissions.find_by_name("Pro") ? "Pro B2B" : todolegal_status
    todolegal_status = user.permissions.find_by_name("Admin") ? "Admin" : todolegal_status

    stripe_status = "Sin Plan"
    if user.stripe_customer_id
      customer = Stripe::Customer.retrieve(user.stripe_customer_id)
      if current_user_plan_is_active(customer)
        stripe_status = "Pro Stripe"
      else
        stripe_status = "Downgraded"
      end
    end
    
    return todolegal_status, stripe_status
  end

  def ley_abierta_url
    "https://leyabierta.todolegal.app/"
  end

  def valid_url
    "https://valid.todolegal.app"
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

  def form_url_field document
    if !document.url.blank?
      return document.url
    elsif !document.issue_id.blank?
      return I18n.transliterate(document.issue_id.gsub(/\s/, "-"))
    elsif !document.name.blank?
      return I18n.transliterate(document.name.gsub(/\s/, "-"))
    else
      return "documento"
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

  def update_mixpanel_user user
    todolegal_status, stripe_status = return_user_plan_status(user)
    $tracker.people.set(user.id, {
      '$email'            => user.email,
      'first_name'      => user.first_name,
      'last_name'      => user.last_name,
      'phone_number'      => user.phone_number,
      'stripe_status'     => stripe_status,
      'todolegal_status' => todolegal_status,
      'current_sign_in_at'      => user.current_sign_in_at,
      'last_sign_in_at'      => user.last_sign_in_at,
      'current_sign_in_ip'      => user.current_sign_in_ip,
      'last_sign_in_ip'      => user.last_sign_in_ip,
      'receive_information_emails'      => user.receive_information_emails
    }, ip = user.current_sign_in_ip, {'$ignore_time' => 'true'});
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
