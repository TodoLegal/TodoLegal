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

  def google_drive_documents_count
    google_drive_data_json_path = 'public/google_drive_data.json'
    google_drive_files_count = 0
    if File.file?(google_drive_data_json_path)
      file = File.read(google_drive_data_json_path)
      data_hash = JSON.parse(file)
      google_drive_files_count =  data_hash['file_count']
    end
    return google_drive_files_count
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
    Law.count + google_drive_documents_count + google_drive_covid_documents_count
  end
end
