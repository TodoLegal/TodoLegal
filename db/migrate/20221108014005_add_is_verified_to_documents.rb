class AddIsVerifiedToDocuments < ActiveRecord::Migration[6.1]
  def change
    add_column :documents, :is_verified, :boolean
  end
end
