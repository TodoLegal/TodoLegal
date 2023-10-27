class RenameIsVerifiedToStatusInVerificationHistories < ActiveRecord::Migration[6.1]
  def change
    rename_column :verification_histories, :is_verified, :status
  end
end
