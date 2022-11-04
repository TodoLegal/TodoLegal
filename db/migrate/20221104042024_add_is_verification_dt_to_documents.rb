class AddIsVerificationDtToDocuments < ActiveRecord::Migration[6.1]
  def change
    add_column :documents, :verification_dt, :datetime
  end
end
