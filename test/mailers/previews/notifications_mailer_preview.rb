# Preview all emails at http://localhost:3000/rails/mailers/notifications_mailer
class NotificationsMailerPreview < ActionMailer::Preview
    def user_preferences_mail
        NotificationsMailer.user_preferences_mail(User.first, Document.limit(200))
    end

    def pro_without_active_notifications
        NotificationsMailer.pro_without_active_notifications(User.first)
    end

    def basic_without_active_notifications
        NotificationsMailer.basic_without_active_notifications(User.first)
    end

    def basic_with_active_notifications
        NotificationsMailer.basic_with_active_notifications(User.first)
    end

    def cancel_notifications
        NotificationsMailer.cancel_notifications(User.first)
    end
end
