module ApplicationHelper
  def current_user_is_admin
    current_user && current_user.permissions.find_by_name("Admin")
  end

  def current_user_is_pro
    current_user && current_user.permissions.find_by_name("Pro")
  end

  def is_editor_mode_enabled
    session[:edit_mode_enabled]
  end
end
