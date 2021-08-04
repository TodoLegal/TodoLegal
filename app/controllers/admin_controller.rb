class AdminController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_admin!, only: [:gazettes, :gazette, :users, :download_contributor_users, :download_recieve_information_users, :grant_permission, :revoke_permission, :set_law_access]

  def gazettes
    @query = params["query"]
    if !@query.blank?
      if @query && @query.length == 5 && @query[1] != ','
        @query.insert(2, ",")
      end
      @gazettes = Document.where(publication_number: @query)
        .group_by(&:publication_number)
        .sort_by { |x | [ x ] }.reverse
      @gazettes_pagination = Kaminari.paginate_array(@gazettes).page(params[:page]).per(1)
    else
      @gazettes = Document.where.not(publication_number: nil).group_by(&:publication_number).sort_by { | x | [ x ] }.reverse
      @gazettes_pagination = Kaminari.paginate_array(@gazettes).page(params[:page]).per(1)
    end
    gazette_temp = @gazettes.first
    @missing_gazettes = []
    @gazettes.drop(1).each do |gazette|
      if gazette.first and gazette_temp.first and gazette.first.delete(',').to_i + 1 != gazette_temp.first.delete(',').to_i
        for missing_gazette in gazette.first.delete(',').to_i+1..gazette_temp.first.delete(',').to_i-1
          @missing_gazettes.push(missing_gazette)
        end
      end
      gazette_temp = gazette
    end
    @has_original_gazette = []
    @has_been_sliced = []
    @sliced_count = 0
    @gazettes.each do |gazette|
      documents = gazette.second
      has_original = false
      is_sliced = false
      documents.each do |document|
        if document.name == "Gaceta"
          has_original = true
        else
          is_sliced = true
        end
      end
      @sliced_count += 1 if is_sliced
      additional_data = {'has_original': has_original, 'is_sliced': is_sliced }
      gazette.push(additional_data)
    end
  end

  def gazette
    @documents = Document.where(publication_number: params[:publication_number])
  end

  def users
    @email = params[:email]
    if @email
      @users = User.where('email LIKE ?', "%#{@email}%")
    else
      @users = User.all.limit(10)
    end
    @permissions = Permission.all

    respond_to do |format|
      format.html
    end
  end

  def download_all_users
    @users = User.all
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
        headers['Content-Disposition'] = "attachment; filename=\"TL_all_users\""
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
        headers['Content-Disposition'] = "attachment; filename=\"TL_contributors_users\""
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
        headers['Content-Disposition'] = "attachment; filename=\"TL_recieve_information_users\""
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
  
