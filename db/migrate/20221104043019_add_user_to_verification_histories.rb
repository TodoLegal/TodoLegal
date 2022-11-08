class AddUserToVerificationHistories < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key  :verification_histories, :users
  end
end
