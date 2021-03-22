class ActiveStorageRedirectController < ActiveStorage::Blobs::RedirectController
    include ActiveStorage::SetBlob
    include ApplicationHelper
  
    def show
      user_document_visit_tracker = get_user_document_visit_tracker
      user_document_visit_tracker.visits += 1
      user_document_visit_tracker.save
      if can_access_documents user_document_visit_tracker
        super
      else
        redirect_to "http://valid.todolegal.app?error='invalid permissions'"
        return
      end
    end
  end