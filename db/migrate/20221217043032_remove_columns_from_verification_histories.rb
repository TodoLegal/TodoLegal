class RemoveColumnsFromVerificationHistories < ActiveRecord::Migration[6.1]
  def change
    remove_columns :verification_histories, :status, :verification_dt, :document_tag_id
  end
end
