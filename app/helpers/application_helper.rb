module ApplicationHelper
  def current_user_is_admin
    current_user && current_user.permissions.find_by_name("Admin")
  end

  def current_user_is_pro
    current_user && current_user.permissions.find_by_name("Pro")
  end
end
