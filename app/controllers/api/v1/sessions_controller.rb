class Api::V1::SessionsController < Devise::SessionsController
  #skip_before_action :verify_signed_out_user, only[:destroy]
  protect_from_forgery with: :null_session
  include ApplicationHelper
  include Api::V1::TurnstileVerifiable
  before_action :doorkeeper_authorize!, only: [:me]

  def create
    user = warden.authenticate!({user: params[:user]})
    sign_in(resource_name, user)

    respond_to do |format|
      format.json do
        render json: {
          user: current_user
        }
      end
    end
  end

  def destroy
    respond_to do |format|
      format.json do
        if doorkeeper_token.present?
          doorkeeper_token.revoke
          sign_out(current_user) if current_user
          render json: {'message': 'You are now logged out.'}, status: :ok
        else
          render json: {'error': 'No valid access token.'}, status: :unauthorized
        end
      end
    end
  end

  def me
    user = User.find_by_id(doorkeeper_token.resource_owner_id)
    render json: {"user": user.as_json(only: [:id, :first_name, :last_name, :email]),
      "user_type": current_user_type_api(user),
      "user_permission": user ? current_user_permission(user) : "",
      "confirmed_user": user ? user.confirmed_at? : false,
      "can_access": can_access_documents(user),
      "remaining_free_trial": remaining_free_trial_time(user)
    }

    if user
      $tracker.track(user.id, 'Valid Session', {
        'user_type' => current_user_type_api(user),
        'is_email_confirmed' =>  user.confirmed_at?,
        'has_notifications_activated': UsersPreference.find_by(user_id: user.id) != nil,
        'session_date' => DateTime.now - 6.hours,
        'location' => "Valid (API)"
      })

      #updates user info in mixpanel
      update_mixpanel_user user
    end
  end

end