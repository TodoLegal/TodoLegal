module ApplicationHelper
  def current_user_is_admin
    current_user && current_user.permissions.find_by_name("Admin")
  end

  def current_user_is_editor
    current_user && (current_user.permissions.find_by_name("Editor") || current_user.permissions.find_by_name("Admin"))
  end

  def current_user_is_pro
    current_user && current_user.permissions.find_by_name("Pro")
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
    return (request.remote_ip +
      browser.to_s +
      browser.device.name +
      browser.device.id.to_s +
      browser.platform.name).hash.to_s
  end
  def get_user_document_visit_tracker
    fingerprint = get_fingerprint
    user_document_visit_tracker = UserDocumentVisitTracker.find_by_fingerprint(fingerprint)
    if !user_document_visit_tracker
      user_document_visit_tracker = UserDocumentVisitTracker.create(fingerprint: fingerprint, visits: 0, period_start: DateTime.now)
    end
    if user_document_visit_tracker.period_start <= 1.month.ago # TODO set time window
      user_document_visit_tracker.period_start = DateTime.now
      user_document_visit_tracker.visits = 0
      user_document_visit_tracker.save
    end
    return user_document_visit_tracker
  end
  def can_access_documents(user_document_visit_tracker, current_user_type)
    if current_user_type == "pro"
      return true
    elsif current_user_type == "basic"
      return user_document_visit_tracker.visits <= 10 # TODO set amount of visits
    else
      return user_document_visit_tracker.visits <= 5 # TODO set amount of visits
    end
  end
  def current_user_type user
    if user
      if !user.stripe_customer_id.blank?
        customer = Stripe::Customer.retrieve(user.stripe_customer_id)
      end
      if customer and current_user_plan_is_active customer
        return "pro"
      else
        return "basic"
      end
    end
    return "not logged"
  end

  def ley_abierta_url
    "https://pod.link/LeyAbierta/"
  end

  def user_browser_language_is_english
    browser_locale = request.env['HTTP_ACCEPT_LANGUAGE'].try(:scan, /^[a-z]{2}/).try(:first) 
    return browser_locale.eql? "en"
  end

end
