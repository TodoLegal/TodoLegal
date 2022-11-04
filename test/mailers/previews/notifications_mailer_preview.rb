# Preview all emails at http://localhost:3000/rails/mailers/notifications_mailer
class NotificationsMailerPreview < ActionMailer::Preview
    def user_preferences_mail
        NotificationsMailer.user_preferences_mail(User.first, Document.all)
    end
end
