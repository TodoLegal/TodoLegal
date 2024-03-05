class ActiveStorageRedirectController < ActiveStorage::Blobs::RedirectController
  include ActiveStorage::SetBlob
  include ApplicationHelper

  before_action :doorkeeper_authorize!, only: [:show]
  # before_action :already_logged_in_user 
  skip_before_action :doorkeeper_authorize!, unless: :has_access_token?

  def show
    user = nil
    user_id = 0
    if params[:access_token]
      user = User.find_by_id(doorkeeper_token.resource_owner_id)
      user_id_str = user.id.to_s
      user_id = user.id
    elsif current_user
      user = current_user
    end

    can_access_document = can_access_documents(user)
    user_trial = user.user_trial
    
    if user && current_user_type_api(user) != "pro" && current_user
      user_trial.downloads += 1
    end

    #if Pro user is not confirmed, add a download to the db. 
    if user && current_user_type_api(user) == "pro" && !user.confirmed_at? && current_user
      user_trial.downloads += 1
    end

    if user && can_access_document && current_user
      $tracker.track(user_id, 'Valid download', {
        'user_type' => current_user_type_api(user),
        'document_name' => params[:document_name],
        'document_id' => params[:document_id],
        'location' => "API"
      })
      user_trial.save
      super
    else
      if current_user
        redirect_to "http://valid.todolegal.app?error='invalid permissions'", allow_other_host: true
      end
     return
    end
    
    # if user.user_trial.downloads >= MAXIMUM_UNCONFIRMED_USER_DOWNLOADS && current_user_type_api(user) != "pro"
    #   if ENV['MAILGUN_KEY']
    #     SubscriptionsMailer.free_trial_end(user).deliver
    #     SubscriptionsMailer.discount_coupon(user).deliver_later(wait_until: 3.day.from_now)
    #   end
    # end
    
  end

  def already_logged_in_user
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
        #  destroy
         warden.raw_session.clear
         warden.logout(scope)
         throw :warden, scope: scope, message: :session_limited
         redirect_to 'https://todolegal.app/users/sign_in'
       end
      end
    end
  end

protected
  def has_access_token?
    return params[:access_token]
  end
end
