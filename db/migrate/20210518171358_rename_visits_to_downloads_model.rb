class RenameVisitsToDownloadsModel < ActiveRecord::Migration[6.1]
  def change
    rename_table :user_document_visit_trackers, :user_document_download_trackers
  end
end
