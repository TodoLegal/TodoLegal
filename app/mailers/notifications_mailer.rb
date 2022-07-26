class NotificationsMailer < ApplicationMailer
  default from: 'TodoLegal <suscripciones@todolegal.app>'
  helper ApplicationHelper

  def is_a_valid_email?(email)
    #email_regex = %r{/\b[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}\z/}xi # Case insensitive
    #(email =~ email_regex)
  end

  def user_preferences_mail(user, notif_arr) 
      @user = user
      @user_preferences = UsersPreference.find_by(user_id: @user.id)
      @user_notifications_history = UserNotificationsHistory.find_by(user_id: @user.id)
      @last_email_sent_date = @user_notifications_history ? @user_notifications_history.mail_sent_at : DateTime.now - @user_preferences.mail_frequency.minutes
      @documents_to_send = []

      docs = notif_arr.sort_by{|item| item.tag_id }
      current_tag_name = ""
      temp_docs = []

      docs.each do |doc|
        tag_name = Tag.find_by(id: doc.tag_id).name
        if tag_name != current_tag_name || doc == docs.last

          if doc == docs.last
            temp_docs.push(doc)
          end

          if temp_docs.length > 0
            @documents_to_send.push({
              "tag_name": current_tag_name,
              "documents": temp_docs
            })
            temp_docs = []
          end
          current_tag_name = tag_name
        end
        temp_docs.push(doc)
      end

      mail(from: 'TodoLegal <suscripciones@todolegal.app>', to: @user.email, subject: 'Notificaciones personalizadas.')

      #checks if user has a history, if it does, schedules a new job
      if @user_notifications_history
        job = MailUserPreferencesJob.set(wait: @user_preferences.mail_frequency.minutes).perform_later(@user)
        @user_preferences.job_id = job.provider_job_id
        @user_preferences.save
      end
  end

end
