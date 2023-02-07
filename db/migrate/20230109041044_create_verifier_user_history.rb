class CreateVerifierUserHistory < ActiveRecord::Migration[6.1]
  def change
    create_table :verifier_user_histories do |t|
      t.integer :user_id
      t.integer :verified_data_points
      t.integer :verification_time
      t.datetime :verification_dt

      t.timestamps
    end
  end
end
