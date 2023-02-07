class AddVerificationDateToVerificationHistories < ActiveRecord::Migration[6.1]
  def change
    add_column :verification_histories, :verification_dt, :datetime
  end
end
