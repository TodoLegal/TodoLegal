class Api::V1::UsersPreferencesController < ApplicationController
    protect_from_forgery with: :null_session
    include ApplicationHelper
    before_action :doorkeeper_authorize!, only: [:get_user_preferences, :update, :deactivate_notifications]

    def get_user_preferences
        user_preferences = {
            user_preference_tags: [],
            mail_frequency: 0,
            active_notifications: false
        }

        if params[:access_token]
            @user = get_user_by_id
            @preferences = UsersPreference.find_by(user_id: @user.id)
            if @user && @preferences
                user_preferences = @preferences
            end
        end

        render json: { "user_preferences": user_preferences }
    end

    #/api/v1/users_preferences?tags_id[]=4&tags_id[]=27&tags_id[]=41&frequency=15&access_token=uK1AGqqD_n4u7g3zh46K2Ce8Wo8KCk
    def update
        #default values in case the user submits just one of the preference values
        default_frequency = 0
        default_tags_id = []

        @user = get_user_by_id
        if @user
            @user_preference = UsersPreference.find_by(user_id: @user.id)
            #checks if user already has preferences, if not, creates preferences
            if @user_preference
                old_frequency = @user_preference.mail_frequency
                if !params["tags_id"].blank? and params["tags_id"].kind_of?(Array)
                    default_tags_id = params["tags_id"]
                end
                if !params["mail_frequency"].blank?
                    default_frequency = params["mail_frequency"]
                end
                @user_preference.user_preference_tags = default_tags_id
                @user_preference.mail_frequency = default_frequency.to_i
                @user_preference.save

                #deletes old job and schedules a new one with updated frequency
                if default_frequency.to_i > 0 && default_frequency.to_i != old_frequency
                    new_job = MailUserPreferencesJob.set(wait: default_frequency.to_i.days).perform_later(@user)
                    delete_user_notifications_job(@user_preference.job_id)
                    @user_preference.job_id = new_job.provider_job_id
                    @user_preference.save
                end

                $tracker.track(@user.id, 'Preferences edition', {
                    'user_type' => current_user_type_api(@user),
                    'selected_tags' => get_tags_name(default_tags_id),
                    'selected_mail_frequency' => default_frequency,
                    'location' => "API"
                })
            else
                if !params["mail_frequency"].blank?
                    default_frequency = params["mail_frequency"]
                end
                if !params["tags_id"].blank?
                    default_tags_id = params["tags_id"]
                end
                @preferences = UsersPreference.create(user_id: @user.id, mail_frequency: default_frequency, user_preference_tags: default_tags_id)

                if default_frequency.to_i > 0
                    #send an email the next day only if the user selected a frequency greater than 1 day
                    # if default_frequency.to_i != 1
                    #     MailUserPreferencesJob.set(wait: 1.day).perform_later(@user)
                    # end
                    job = MailUserPreferencesJob.set(wait: default_frequency.to_i.days).perform_later(@user)
                    @preferences.job_id = job.provider_job_id
                    @preferences.save
                end

                $tracker.track(@user.id, 'Preferences edition', {
                    'user_type' => current_user_type_api(@user),
                    'selected_tags' => get_tags_name(default_tags_id),
                    'selected_mail_frequency' => default_frequency,
                    'location' => "API"
                })
            end
            render json: {message: "User successfully updated."}, status: 200
        else
            render json: {message: "Unable to update user."}, status: :unprocesable_entity
        end
    end

     #/api/v1/users_preferences/deactivate_notifications?access_token=uK1AGqqD_n4u7g3zh46K2Ce8Wo8KCk
    def deactivate_notifications
        user = get_user_by_id
        user_preferences = UsersPreference.find_by(user_id: user.id)
        if user && user_preferences
            if user_preferences.active_notifications
                delete_user_notifications_job(user_preferences.job_id)
            else
                delete_user_notifications_job(user_preferences.job_id)
                
                enqueue_new_job(user)
            end
            user_preferences = UsersPreference.find_by(user_id: user.id)
            user_preferences.active_notifications = !user_preferences.active_notifications
            user_preferences.save
            render json: {message: "User successfully updated."}, status: 200
        else
            render json: {message: "Unable to update user."}, status: :unprocesable_entity
        end
    end

    protected
        def get_user_by_id
            return User.find_by_id(doorkeeper_token.resource_owner_id)
        end
end
