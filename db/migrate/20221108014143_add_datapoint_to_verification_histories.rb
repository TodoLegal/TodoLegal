class AddDatapointToVerificationHistories < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key :verification_histories, :datapoints
  end
end
