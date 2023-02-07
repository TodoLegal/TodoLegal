class AddColumnsToVerifierUserHistories < ActiveRecord::Migration[6.1]
  def change
    add_column :verifier_user_histories, :verification_type, :string
    add_column :verifier_user_histories, :skipped_elements, :integer, array: true, default: []
  end
end

