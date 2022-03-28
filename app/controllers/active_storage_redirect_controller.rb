class ActiveStorageRedirectController < ActiveStorage::Blobs::RedirectController
  include ActiveStorage::SetBlob
  include ApplicationHelper

  before_action :doorkeeper_authorize!, only: [:show]
  skip_before_action :doorkeeper_authorize!, unless: :has_access_token?

  def show
    user_id_str = "" #here
    if params[:access_token]
      user = User.find_by_id(doorkeeper_token.resource_owner_id)
      user_id_str = user.id.to_s #here
    elsif current_user
      user = current_user
    end

    # if user && current_user_type_api(user) == "pro"
    #   super
    # else
    #   redirect_to "http://valid.todolegal.app?error='invalid permissions'"
    #   return
    # end

    #from here
    user_document_download_tracker = get_user_document_download_tracker(user_id_str)
    can_access_document = can_access_documents(user_document_download_tracker, current_user_type_api(user))
    if user && current_user_type_api(user) != "pro"
     user_document_download_tracker.downloads += 1
    end
    if user && can_access_document
     user_document_download_tracker.save
     super
    else
     redirect_to "http://valid.todolegal.app?error='invalid permissions'"
     return
    end
    #to here

    if  user_document_download_tracker.downloads >= 3 and current_user_type_api(user) != "pro"
      if ENV['MAILGUN_KEY']
        SubscriptionsMailer.free_trial_end(current_user).deliver
      end
    end
    
  end

protected
  def has_access_token?
    return params[:access_token]
  end
end