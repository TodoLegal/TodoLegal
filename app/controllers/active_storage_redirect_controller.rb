class ActiveStorageRedirectController < ActiveStorage::Blobs::RedirectController
  include ActiveStorage::SetBlob
  include ApplicationHelper

  before_action :doorkeeper_authorize!, only: [:show]
  skip_before_action :doorkeeper_authorize!, unless: :has_access_token?

  def show
    #user_id_str = ""
    if params[:access_token]
      user = User.find_by_id(doorkeeper_token.resource_owner_id)
      #user_id_str = user.id.to_s
    elsif current_user
      user = current_user
    end

    if user && current_user_type(user) == "pro"
      super
    else
      redirect_to "http://valid.todolegal.app?error='invalid permissions'"
      return
    end

    #user_document_download_tracker = get_user_document_download_tracker(user_id_str)
    #can_access_document = can_access_documents(user_document_download_tracker, current_user_type(user))
    #if current_user_type(user) != "pro"
    #  user_document_download_tracker.downloads += 1
    #end
    #if can_access_document
    #  user_document_download_tracker.save
    #  super
    #else
    #  redirect_to "http://valid.todolegal.app?error='invalid permissions'"
    #  return
    #end
  end

protected
  def has_access_token?
    return params[:access_token]
  end
end