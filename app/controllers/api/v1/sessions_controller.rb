class Api::V1::SessionsController < Devise::SessionsController
  #skip_before_action :verify_signed_out_user, only[:destroy]
  protect_from_forgery with: :null_session
  include ApplicationHelper
  before_action :already_logged_in2
  before_action :doorkeeper_authorize!, only: [:me,:already_logged_in2]

  def create
    user = warden.authenticate!({user: params[:user]})
    sign_in(resource_name, user)

    current_user.authentication_token = nil
    current_user.save

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
      user = User.find_by authentication_token: params[:authentication_token]
      format.json do
        if user
          user.authentication_token = nil
          user.save
          sign_out(user)
          render json: {'message': 'You are now logged out.'}, status: :ok
        else
          render json: {'error': 'Invalid authentication token.'}, status: :unprocesable_entity
        end
      end
    end
  end

  def me
    user = User.find_by_id(doorkeeper_token.resource_owner_id)
    # if current_user.confirmed_at? == false
    #   current_user.send_confirmation_instructions
    # end 
    render json: {"user": user,
      "user_type": current_user_type_api(user),
      "confirmed_user": user ? user.confirmed_at? : false
    }
    already_logged_in2()
  end

  def already_logged_in2
    Warden::Manager.after_set_user only: :fetch do |record, warden, options|
      scope = options[:scope]
      if record.devise_modules.include?(:session_limitable) &&
        warden.authenticated?(scope) &&
        options[:store] != false
       if record.unique_session_id != warden.session(scope)['unique_session_id'] &&
          !record.skip_session_limitable? && 
          !warden.session(scope)['devise.skip_session_limitable']
         Rails.logger.warn do
           '[devise-security][session_limitable] session id mismatch: '\
           "expected=#{record.unique_session_id.inspect} "\
           "actual=#{warden.session(scope)['unique_session_id'].inspect}"
         end
         redirect_to '/users/edit'
         warden.raw_session.clear
         warden.logout(scope)
         throw :warden, scope: scope, message: :session_limited
         
       end
      end
    end
  end

end