class ChangeStatusToBeIntegerInVerificationHistories < ActiveRecord::Migration[6.1]
  def change
    change_column :verification_histories, :status, :integer, using: 'status::integer'
  end
end
