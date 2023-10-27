class RemoveColumnWithForeignKeyFromVerificationHistories < ActiveRecord::Migration[6.1]
  def change
    remove_reference :verification_histories, :document, index: true, foreign_key: true
  end
end
