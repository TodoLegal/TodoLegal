class CreateSliceVerificationHistories < ActiveRecord::Migration[6.1]
  def change
    create_table :slice_verification_histories do |t|
      t.integer :document_slice_id
      t.integer :user_id
      t.string :selected_status
      t.text :comments
      t.datetime :verification_dt

      t.timestamps
    end
  end
end
