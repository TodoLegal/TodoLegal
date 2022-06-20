class Api::V1::UsersPreferencesController < ApplicationController
    protect_from_forgery with: :null_session
    include ApplicationHelper
    before_action :doorkeeper_authorize!, only: [:get_user_preferences, :update_user_preferences]

    def get_user_preferences
        user_preferences = []
        if params[:access_token]
            @user = get_user_by_id
            if @user
                user_preferences = UsersPreference.find_by(user_id: @user.id)
            end
        end
        render json: { "user_preferences": user_preferences }
    end

    #/api/v1/users_preferences?tags_id[]=4&tags_id[]=27&tags_id[]=41&frequency=15&access_token=uK1AGqqD_n4u7g3zh46K2Ce8WDwgFwcMTqcARQo8KCk
    def update_user_preferences
        #default values in case the user submits just one of the preference values
        default_frequency = 7
        default_tags_id = []

        @user = get_user_by_id
        if @user
            @user_preference = UsersPreference.find_by(user_id: @user.id)
            #checks if user already has preferences, if not, creates preferences
            if @user_preference
                if !params["tags_id"].blank? and params["tags_id"].kind_of?(Array)
                    @user_preference.user_preference_tags = params["tags_id"]
                end
                if !params["mail_frequency"].blank?
                    @user_preference.mail_frequency = params["mail_frequency"]
                end
                @user_preference.save
            else
                if !params["mail_frequency"].blank?
                    default_frequency = params["mail_frequency"]
                end
                if !params["tags_id"].blank?
                    default_tags_id = params["tags_id"]
                end
                UsersPreference.create(user_id: @user.id, mail_frequency: default_frequency, user_preference_tags: default_tags_id)
            end
            render json: {message: "User successfully updated."}, status: 200
        else
            render json: {message: "Unable to update user."}, status: 400
        end
    end

    protected
        def get_user_by_id
            return User.find_by_id(doorkeeper_token.resource_owner_id)
        end
end
