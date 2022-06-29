class NotificationsMailer < ApplicationMailer
    default from: 'TodoLegal <suscripciones@todolegal.app>'
    helper ApplicationHelper
  
    def is_a_valid_email?(email)
      #email_regex = %r{/\b[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}\z/}xi # Case insensitive
      #(email =~ email_regex)
    end

    def user_preferences_mail(user,notif_arr) 
        @user = user
        @documents_to_send = notif_arr
        #Controllers/ActiveStorageMailer have the jobs.
        mail(from: 'TodoLegal <suscripciones@todolegal.app>', to: user.email, subject: 'Sus leyes importantes.')
    end

end
