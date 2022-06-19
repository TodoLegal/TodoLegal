class Api::V1::UsersPreferencesController < ApplicationController
    protect_from_forgery with: :null_session
    include ApplicationHelper
    before_action :doorkeeper_authorize!, only: [:get_user_preferences, :update_user_preferences]

    def get_user_preferences
        user_preferences = []
        if params[:access_token]
            @user = get_user_by_id
            if @user
                user_preferences = UsersPreference.find_by(id: @user.id)
            end
        end
        render json: { "user_preferences": user_preferences }
    end

    def update_user_preferences
        @user = get_user_by_id
        if @user
            
        end
    end

    private
        def get_user_by_id
            return User.find_by_id(doorkeeper_token.resource_owner_id)
        end
end
