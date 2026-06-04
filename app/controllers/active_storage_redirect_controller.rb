# Handles Active Storage blob downloads for CMS editors authenticated via Devise session.
# API/frontend downloads are handled by Documents::DownloadService via the download_url endpoint.
class ActiveStorageRedirectController < ActiveStorage::Blobs::RedirectController
  include ActiveStorage::SetBlob
  include ApplicationHelper

  before_action :authenticate_user!

  def show
    unless can_access_documents(current_user)
      redirect_back(fallback_location: documents_path, alert: "No tienes permisos para descargar este archivo.")
      return
    end

    super
  end
end