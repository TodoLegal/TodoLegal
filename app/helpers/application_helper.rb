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

  def current_user_permission user
    permission_name = ""
    permission_name = "Pro" if user.permissions.find_by_name("Pro")
    permission_name = "Editor D2" if user.permissions.find_by_name("Editor D2")
    permission_name = "Editor" if user.permissions.find_by_name("Editor")
    permission_name = "Admin" if user.permissions.find_by_name("Admin")

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
    Law.count + Document.where(publish: true) + google_drive_covid_documents_count
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
      subscriptions = Stripe::Subscription.list(customer: customer.id)
      subscriptions.data.each do |subscription|
        if subscription.plan.product == STRIPE_SUBSCRIPTION_PRODUCT and subscription.plan.active
          return true
        end
      end
    rescue => e
      Rails.logger.error e.message
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
    # user_trial = user.user_trial ? true : false
    todolegal_status = user.user_trial && user.user_trial.active ? todolegal_status : "Basic"
    todolegal_status = user.permissions.find_by_name("Editor") ? "Editor" : todolegal_status
    todolegal_status = user.permissions.find_by_name("Pro") ? "Pro B2B" : todolegal_status
    todolegal_status = user.permissions.find_by_name("Admin") ? "Admin" : todolegal_status

    # stripe_status = "Sin Plan"
    if user.stripe_customer_id
      customer = Stripe::Customer.retrieve(user.stripe_customer_id)
      if current_user_plan_is_active(customer)
        todolegal_status = "Pro Stripe"
      end
    end
    return todolegal_status
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
    Document.where(publish: true).count
  end

  def valid_gazettes_count
    Summatory.first.count_sum
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
    # Handle both hash objects (from job processing) and ActiveRecord objects
    if document.is_a?(Hash)
      # Hash object from job processing - check if it has nested :doc structure or is flat
      if document[:doc]
        # Nested structure: document[:doc] contains the actual document data
        doc_data = document[:doc]
      else
        # Flat structure: document itself contains the document data
        doc_data = document
      end
      
      url = doc_data["url"] || doc_data[:url]
      issue_id = doc_data["issue_id"] || doc_data[:issue_id]
      name = doc_data["name"] || doc_data[:name]
    else
      # ActiveRecord object
      url = document.url
      issue_id = document.issue_id
      name = document.name
    end

    if !url.blank?
      return url
    elsif !issue_id.blank?
      return I18n.transliterate(issue_id.gsub(/\s/, "-").gsub(/\\/, "-").gsub(/\./, "-"))
    elsif !name.blank?
      return I18n.transliterate(name.gsub(/\s/, "-").gsub(/\\/, "-").gsub(/\./, "-"))
    else
      return "documento"
    end
  end

  def enqueue_new_job user
    @user_preferences = UsersPreference.find_by(user_id: user.id)
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
      'receive_information_emails'      => user.receive_information_emails,
      'email_confirmed'     => user.confirmed_at?
    }, ip = user.current_sign_in_ip, {'$ignore_time' => 'true'});
  end

  def removeAccents(text)
    accents_map = {
      "A" => /[ÁÀÃÂÄ]/,
      "a" => /[áàãâä]/,
      "E" => /[ÉÈÊË]/,
      "e" => /[éèêë]/,
      "I" => /[ÍÌÎÏ]/,
      "i" => /[íìîï]/,
      "O" => /[ÓÒÔÕÖ]/,
      "o" => /[óòôõö]/,
      "U" => /[ÚÙÛÜ]/,
      "u" => /[úùûü]/,
      "C" => /Ç/,
      "c" => /ç/,
      "N" => /Ñ/,
      "n" => /ñ/
    }
  
    accents_map.each do |unaccented, pattern|
      text.gsub!(pattern, unaccented)
    end
  
    return text
  end

  def clean_session
    session[:pricing_onboarding] = nil
    session[:is_onboarding] = nil
    session[:go_to_checkout] = nil
    session[:go_to_law] = nil
    session[:is_monthly] = nil
    session[:is_annually] = nil
  end

  # Sitemap helper methods
  def document_sitemap_url(document)
    document_type_slug = get_document_type_slug(document)
    url_slug = get_document_url_slug(document)
    
    "https://valid.todolegal.app/#{document_type_slug}/honduras/#{url_slug}/#{document.id}"
  end
  
  def get_document_type_slug(document)
    return 'documento' unless document.document_type
    
    # Handle special case for 'Sección de Gaceta'
    if document.document_type.name == 'Sección de Gaceta'
      act_type_tag = TagType.find_by(name: 'Tipo de Acto')
      type_name = document.tags.find_by(tag_type_id: act_type_tag&.id)
      return (type_name&.name || 'seccion-de-gaceta').parameterize
    end
    
    document.document_type.name.parameterize
  end
  
  def get_document_url_slug(document)
    # Priority: url > name > issue_id > fallback
    if document.url.present?
      document.url
    elsif document.name.present?
      document.name.parameterize
    elsif document.issue_id.present?
      # Clean and parameterize issue_id
      document.issue_id.gsub(/[\/\\]/, '-').parameterize
    else
      'documento'
    end
  end
  
  def document_priority(document)
    # Simple uniform priority for all documents
    # TODO: Uncomment advanced logic below when you want document type-based prioritization
    0.8
    
    # Advanced priority logic (use when you want SEO differentiation):
    # case document.document_type&.name
    # when 'Ley', 'Decreto', 'Constitución'
    #   0.9  # Highest priority - fundamental legal documents
    # when 'Acuerdo', 'Resolución', 'Reglamento'
    #   0.8  # High priority - important regulatory documents
    # when 'Auto Acordado', 'Sentencia'
    #   0.7  # Medium-high priority - judicial decisions
    # when 'Gaceta'
    #   0.6  # Medium priority - official publications
    # else
    #   0.5  # Default priority - other documents
    # end
  end
  
  def document_changefreq(document)
    # Simple uniform frequency for all documents
    # TODO: Uncomment advanced logic below when you want document type-based frequencies
    'monthly'
    
    # Advanced frequency logic (use when you want crawling optimization):
    # case document.document_type&.name
    # when 'Ley', 'Decreto', 'Constitución'
    #   'yearly'   # Very stable content - fundamental documents rarely get page updates
    # when 'Gaceta', 'Avisos Legales'
    #   'never'    # Published once, page content won't change
    # when 'Sentencia'
    #   'monthly'  # Might have related documents or updates added to the page
    # else
    #   'monthly'  # Default for other document types
    # end
  end

end
