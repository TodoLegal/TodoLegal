class AddDocumentToVerificationHistories < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key :verification_histories, :documents
  end
end
