class AdminController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_admin!, only: [:users, :grant_permission, :revoke_permission, :set_law_access, :deactivate_notifications, :activate_notifications, :activate_batch_of_users]
  before_action :authenticate_editor!, only: [:gazette, :gazettes]
  require 'MailchimpMarketing'
  include ApplicationHelper

  def gazettes
    @query = params["query"]
    result = GazetteService.call(params)
    
    @gazettes_pagination = result[:gazettes]
    @missing_gazettes = result[:missing_gazettes]
    @sliced_count = result[:sliced_count]
    @gazettes_count = result[:total_count]
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
    UsersDownloadJob.perform_later current_user
    redirect_back(fallback_location: root_path, notice: "Los usuarios se están extrayendo de la base de datos, se te enviará un correo con el archivo CSV adjunto.")
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

  def setup_mailchimp_client
    client = MailchimpMarketing::Client.new
    client.set_config({ api_key: ENV['MAILCHIMP_API_KEY'], server: ENV['MAILCHIMP_DC']})
    client
  end

  def get_list_members(client, list_id)
    response = client.lists.get_list_members_info(list_id, { count: 500 })
    response['members']
  end

  #set info to show in the mailchimp view
  def mailchimp
    
    @list_members = []
    @suscribed = 0
    @unsuscribed = 0
    @pending = 0
    @archived = 0

    begin
      client = setup_mailchimp_client
      members = get_list_members(client, ENV['MAILCHIMP_LIST_ID'])

      members.each do |member|
        if member['status'] == 'subscribed'
          @list_members << {id: member['id'], name: member['full_name'], email: member['email_address'], status: member['status']}
          @suscribed += 1
        elsif member['status'] == 'unsubscribed'
          @list_members << {id: member['id'], name: member['full_name'], email: member['email_address'], status: member['status']}
          @unsuscribed += 1
        elsif member['status'] == 'archived'
          @list_members << {id: member['id'], name: member['full_name'], email: member['email_address'], status: member['status']}
          @archived += 1
        elsif member['status'] == 'pending'
          @pending += 1
        end
      end
    rescue MailchimpMarketing::ApiError => e
      puts "Error: #{e}"
    end
  end

  def active_users
    # Return all the users that are not 'Basic' users
    users = User.all.select do |user|
      return_user_plan_status(user) != "Basic"
    end
    users
  end

  #update mailchimp list with the users status
  def update_mailchimp
    begin
      client = setup_mailchimp_client
      members = get_list_members(client, ENV['MAILCHIMP_LIST_ID'])
      active_tl_users = active_users()
    
      # Convert members to a hash for quick lookup
      members_hash = members.index_by { |member| member['email_address'] }
    
      # Check every active user
      active_tl_users.each do |user|
        begin
          member = members_hash[user.email]
          
          if member
            # If the user is in the members list, check their status
            if member['status'] == 'subscribed'
              # If the member is subscribed, update the user status to "subscribed"
              user.update(status: "subscribed")
            elsif member['status'] == 'unsubscribed'
              # If the member is unsubscribed, update the user status to "unsubscribed"
              user.update(status: "unsubscribed")
            end
          else
            # If the user is not in the members list, add them to the list as "subscribed"

            if user.status != "unsubscribed"
              new_member = client.lists.add_list_member(ENV['MAILCHIMP_LIST_ID'], {
                email_address: user.email,
                status: "subscribed"
              })
              user.update(status: "subscribed")

              # Add the current year as a tag
              client.lists.update_list_member_tags(ENV['MAILCHIMP_LIST_ID'], new_member['id'], {
                tags: [{ name: Time.now.year.to_s, status: 'active' }]
              })
            end
          end
        rescue => e
          Rails.logger.error("Error in adding a user to the list: #{e}")
        end
      end
    
      # If a user is in the members list but not in the active users list, archive them
      members.each do |member|
        begin
          user = User.find_by(email: member['email_address'])
          next if user.nil?
          plan_status = return_user_plan_status(user)
          if plan_status != "Basic" && member['status'] == 'unsubscribed'
            client.lists.delete_list_member(ENV['MAILCHIMP_LIST_ID'], member['id'])
            #unsubscribe the user will prevent the user to receive any email from mailchimp
            user.update(status: "unsubscribed")
          elsif plan_status == "Basic" && member['status'] == 'subscribed'
            client.lists.delete_list_member(ENV['MAILCHIMP_LIST_ID'], member['id'])
            #archive the user will prevent the user to receive any email from mailchimp, but if the user is reactivated, it will be able to receive emails again
            user.update(status: "archived")
          end
        rescue => e
          Rails.logger.error("Error in archiving a user: #{e}")
        end
      end
    rescue MailchimpMarketing::ApiError => e
      flash[:error] = "Error: #{e}"
    end
    
    redirect_to admin_mailchimp_path, notice: "Se ha actualizado la lista en Mailchimp."
  end

  def check_hyperlink(hyperlink)
    uri = URI.parse(hyperlink)
    response = Net::HTTP.get_response(uri)
  
    # Return 'OK' if the response is a success, 'Not Found' if the response is a 404, or 'Error' otherwise
    case response
    when Net::HTTPSuccess then 'OK'
    when Net::HTTPNotFound then 'Not Found'
    else 'Error'
    end
  rescue
    'Error'
  end


end
  
