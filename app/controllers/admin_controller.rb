class AdminController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_admin!, only: [:users, :grant_permission, :revoke_permission, :set_law_access, :subscriptions]

  def write_users_csv filename, users
    file_path = Rails.root.join("public", filename)

    content = ""

    users.each do |user|
      content += user.email + "\n"
    end

    File.open(file_path, "w+") do |f|
      f.write(content)
    end
  end

  def users
    @email = params[:email]
    if @email
      @users = User.where('email LIKE ?', "%#{@email}%")
    else
      @users = User.all
    end
    @permissions = Permission.all

    write_users_csv 'users.csv', @users
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

  def subscriptions
    @subscriptions = EmailSubscription.all
    @confirmed_subscriptions = EmailSubscription.where(status: "confirmed")
    @pending_subscriptions = EmailSubscription.where(status: "pending")

    write_users_csv 'confirmed.csv', @confirmed_subscriptions
    write_users_csv 'pending.csv', @pending_subscriptions
  end
end
  