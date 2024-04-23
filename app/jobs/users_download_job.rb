class UsersDownloadJob < ApplicationJob
  queue_as :default
  include ApplicationHelper

  def perform user
    @users = User.all
    headers = ['Name', 'Last name', 'Email', 'Created', 'Last signed in', 'Status']
    csv_data = CSV.generate(headers: true) do |csv|
      csv << headers
      @users.each do |user|
        status = return_user_plan_status(user)
        if status != "Basic"
          csv << [user.first_name, user.last_name, user.email, user.created_at, user.last_sign_in_at, status]
        end
      end
    end
    UsersDownloadMailer.send_csv_email(user, csv_data).deliver_now
  end
end
