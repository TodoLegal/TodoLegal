class AdminController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_admin!, only: [:users, :download_contributor_users, :download_recieve_information_users, :grant_permission, :revoke_permission, :set_law_access]

  def users
    @email = params[:email]
    if @email
      @users = User.where('email LIKE ?', "%#{@email}%")
    else
      @users = User.all
    end
    @permissions = Permission.all

    respond_to do |format|
      format.html
      format.csv do
        headers['Content-Disposition'] = "attachment; filename=\"users\""
        headers['Content-Type'] ||= 'text/csv'
      end
    end
  end

  def download_contributor_users
    @users = User.where(is_contributor: true)
    @users.each do |user|
      if user.first_name == nil
        user.first_name = ""
      end
      if user.last_name == nil
        user.last_name = ""
      end
    end
    respond_to do |format|
      format.csv do
        headers['Content-Disposition'] = "attachment; filename=\"contributors_users\""
        headers['Content-Type'] ||= 'text/csv'
      end
    end
  end

  def download_recieve_information_users
    @users = User.where(receive_information_emails: true)
    @users.each do |user|
      if user.first_name == nil
        user.first_name = ""
      end
      if user.last_name == nil
        user.last_name = ""
      end
    end
    respond_to do |format|
      format.csv do
        headers['Content-Disposition'] = "attachment; filename=\"recieve_information_users\""
        headers['Content-Type'] ||= 'text/csv'
      end
    end
  end

  def grant_permission
    user = User.find_by_id(params[:user_id])
    permission = Permission.find_by_id(params[:permission_id])
    @error_message = nil

    if user && permission
      user_permission = UserPermission.find_by(user: user, permission: permission)
      if !user_permission
        UserPermission.create(user: user, permission: permission)
      else
        @error_message = "El usuario ya tenía estos permisos anteriormente."
      end
    else
      @error_message = "No se pudo encontrar el usuario o permiso."
    end
    redirect_to admin_users_url
  end

  def revoke_permission
    user = User.find_by_id(params[:user_id])
    permission = Permission.find_by_id(params[:permission_id])
    @error_message = nil

    if user && permission
      user_permission = UserPermission.find_by(user: user, permission: permission)
      if user_permission
        user_permission.destroy
      else
        @error_message = "El usuario no tiene asignados estos permisos."
      end
    else
      @error_message = "No se pudo encontrar el usuario o permiso."
    end
    redirect_to admin_users_url
  end

  def set_law_access
    law_id = params[:law][:law_id]
    law_access_id = params[:law][:law_access_id]
    @law = Law.find_by_id(law_id)
    @law.law_access_id = law_access_id
    @law.save
    redirect_to laws_path
  end

  def enable_edit_mode
    session[:edit_mode_enabled] = true
    redirect_back(fallback_location: root_path, notice: "Modo editor habilitado.")
  end

  def disable_edit_mode
    session[:edit_mode_enabled] = false
    redirect_back(fallback_location: root_path, notice: "Modo editor deshabilitado.")
  end
end
  