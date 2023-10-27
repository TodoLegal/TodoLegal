class AddStatusToVerificationHistories < ActiveRecord::Migration[6.1]
  def change
    add_column :verification_histories, :selected_status, :string
  end
end
