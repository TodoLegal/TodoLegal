class CreateUserTrials < ActiveRecord::Migration[6.1]
  def change
    create_table :user_trials do |t|
      t.integer :user_id
      t.datetime :trial_start
      t.datetime :trial_end
      t.integer :downloads, default: 0
      t.boolean :active

      t.timestamps
    end
  end
end
