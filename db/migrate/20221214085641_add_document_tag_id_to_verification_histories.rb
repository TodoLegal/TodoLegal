class AddDocumentTagIdToVerificationHistories < ActiveRecord::Migration[6.1]
  def change
    add_column :verification_histories, :document_tag_id, :integer
  end
end
