# Preview all emails at http://localhost:3000/rails/mailers/users_download_mailer
class UsersDownloadMailerPreview < ActionMailer::Preview
  
    def send_csv_email
      @users = User.last(5)
      headers = ['Name', 'Last name', 'Email', 'Created', 'Last signed in', 'Status']
      csv_data = CSV.generate(headers: true) do |csv|
        csv << headers
        @users.each do |user|
          status = "Test"
          csv << [user.first_name, user.last_name, user.email, user.created_at, user.last_sign_in_at, status]
        end
      end

      UsersDownloadMailer.send_csv_email(User.first, csv_data)
    end
end
