class AddPhoneNumberToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :phone_number, :text, default: ""
  end
end
