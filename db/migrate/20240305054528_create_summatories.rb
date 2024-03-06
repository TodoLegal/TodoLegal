class CreateSummatories < ActiveRecord::Migration[7.1]
  def change
    create_table :summatories do |t|
      t.float :count_sum

      t.timestamps
    end
  end
end
