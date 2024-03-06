class ChangeDataTypeForCountNum < ActiveRecord::Migration[7.1]
  def self.up
    change_table :summatories do |t|
      t.change :count_sum, :integer
    end
  end
  def self.down
    change_table :summatories do |t|
      t.change :count_sum, :float
    end
  end
end
