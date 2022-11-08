class CreateVerificationHistories < ActiveRecord::Migration[6.1]
  def change
    create_table :verification_histories do |t|
      t.integer :datapoint_id
      t.integer :document_id
      t.integer :user_id
      t.boolean :is_verified
      t.datetime :verification_dt
      t.text :comments
      t.boolean :is_active

      t.timestamps
    end
  end
end
