class AdminController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_admin!, only: [:gazette, :users, :download_contributor_users, :download_recieve_information_users, :grant_permission, :revoke_permission, :set_law_access, :deactivate_notifications, :activate_notifications, :activate_batch_of_users]
  before_action :authenticate_editor!, only: [:gazettes]
  include ApplicationHelper

  def gazettes
    @query = params["query"]
    if !@query.blank?
      if @query && @query.length == 5 && @query[1] != ','
        @query.insert(2, ",")
      end
      @gazettes = Document.where(publication_number: @query)
        .group_by(&:publication_number)
        .sort_by { |x | [ x ] }.reverse
      @gazettes_pagination = Kaminari.paginate_array(@gazettes).page(params[:page]).per(20)
    else
      @gazettes = Document.where.not(publication_number: nil).group_by(&:publication_number).sort_by { | x | [ x ] }.reverse
      @gazettes_pagination = Kaminari.paginate_array(@gazettes).page(params[:page]).per(20)
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

    @users_with_free_trial = UserTrial.count
    @users_left = User.count - UserTrial.count

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
        
        #activates notifications if user was given "Pro" permission
        if permission.name == "Pro"
          user_preferences = UsersPreference.find_by(user_id: user.id)
          if user_preferences
            delete_user_notifications_job(user_preferences.job_id)
            enqueue_new_job(user)
          end
        end
        
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

  def deactivate_notifications
    user = User.find_by_id(params[:user_id])
    user_preferences = UsersPreference.find_by(user_id: user.id)
    @error_message = nil

    if user
      user_preferences = UsersPreference.find_by(user_id: user.id)
      if user_preferences
        user_preferences.active_notifications = false
        user_preferences.save
        delete_user_notifications_job(user_preferences.job_id)
      else
        @error_message = "El usuario no tiene preferencias/notificaciones activas."
      end
    else
      @error_message = "No se pudo encontrar el usuario"
    end

    redirect_to admin_users_url
  end

  def activate_notifications
    user = User.find_by_id(params[:user_id])
    user_preferences = UsersPreference.find_by(user_id: user.id)
    @error_message = nil

    if user
      user_preferences = UsersPreference.find_by(user_id: user.id)
      if user_preferences
        user_preferences.active_notifications = true
        user_preferences.save
        enqueue_new_job(user)
      else
        @error_message = "El usuario no tiene preferencias/notificaciones activas."
      end
    else
      @error_message = "No se pudo encontrar el usuario"
    end

    redirect_to admin_users_url
  end


  def get_users_with_free_trial_activated
    User.joins(:user_trial).count
  end

  def activate_batch_of_users
    default_tags_names = ["Tributario", "Reformas y Derogaciones", "Aduanero e Import-Export", "Subsidios", "Mercantil", "Congreso Nacional", "Secretaría de Desarrollo Económico"]
    default_tags_id = []
    default_frequency = 1

    default_tags_names.each do | tag_name |
      tag = Tag.find_by(name: tag_name);
      if tag
        default_tags_id.push(tag.id)
      end
    end

    batch_of_users = User.ignore_users_whith_free_trial.order(created_at: :asc).last(50)

    batch_of_users.each do | user |
      #first create a free_trial entry
      user_trial = UserTrial.create(user_id: user.id, trial_start: DateTime.now, trial_end: DateTime.now + 2.weeks, active: true)
      
      #check if the user has active notifications
      user_has_preferences = user.users_preference
      if user_has_preferences
        if current_user_type_api(user) != "pro" 
          NotificationsMailer.basic_with_active_notifications(user).deliver
          SubscriptionsMailer.free_trial_end(user).deliver_later(wait_until: user_trial.trial_end - 1.days)
          NotificationsMailer.cancel_notifications(user).deliver_later(wait_until: user_trial.trial_end)
        end
      else
        user_preferences = UsersPreference.create(user_id: user.id, mail_frequency: default_frequency, user_preference_tags: default_tags_id)
        if current_user_type_api(user) != "pro"
          NotificationsMailer.basic_without_active_notifications(user).deliver
          SubscriptionsMailer.free_trial_end(user).deliver_later(wait_until: user_trial.trial_end - 1.days)
          NotificationsMailer.cancel_notifications(user).deliver_later(wait_until: user_trial.trial_end)
        elsif current_user_type_api(user) == "pro"
          NotificationsMailer.pro_without_active_notifications(user).deliver
          user_trial.active = false
          user_trial.save
        end
        enqueue_new_job(user)
      end

    end

    redirect_to admin_users_url

  end


end
  
