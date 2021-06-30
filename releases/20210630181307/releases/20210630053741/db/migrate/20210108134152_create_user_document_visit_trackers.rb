class CreateUserDocumentVisitTrackers < ActiveRecord::Migration[6.0]
  def change
    create_table :user_document_visit_trackers do |t|
      t.string :fingerprint
      t.integer :visits
      t.datetime :period_start

      t.timestamps
    end
  end
end
