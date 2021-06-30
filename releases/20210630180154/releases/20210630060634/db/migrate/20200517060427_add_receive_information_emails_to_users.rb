class AddReceiveInformationEmailsToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :receive_information_emails, :boolean
  end
end
