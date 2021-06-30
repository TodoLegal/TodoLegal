class RenameVisitsToDownloadsField < ActiveRecord::Migration[6.1]
  def change
    rename_column :user_document_visit_trackers, :visits, :downloads
  end
end
