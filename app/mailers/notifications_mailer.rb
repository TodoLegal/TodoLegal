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
      @documents_to_send = []

      docs = notif_arr.sort_by{|item| item.tag_id }
      current_tag_name = ""
      temp_docs = []

      @act_type_tag = TagType.find_by(name: "Tipo de Acto")
      
      docs.each do |doc|
        tag = Tag.find_by(id: doc.tag_id)

        act_type_tag = nil

        #obtains the Tipo de Acto tag from each document
        act_type_tag = Tag.joins(:document_tags).where( document_tags: {document_id: doc.id}).where(tags: {tag_type_id: @act_type_tag.id})
        act_type_tag = act_type_tag.first ? act_type_tag.first.name : nil

        if tag.name != current_tag_name || doc == docs.last

          if doc == docs.last
            if tag.name != current_tag_name && temp_docs.length > 0
              @documents_to_send.push({
                "tag_name": current_tag_name == "" ? tag.name : current_tag_name,
                "documents": temp_docs
              })
              temp_docs = []
            end

            temp_docs.push({
              doc: doc,
              act_type: act_type_tag
            })
            current_tag_name = tag.name
          end

          if temp_docs.length > 0
            @documents_to_send.push({
              "tag_name": current_tag_name == "" ? tag.name : current_tag_name,
              "documents": temp_docs
            })
            temp_docs = []
          end
          current_tag_name = tag.name
        end

        temp_docs.push({
          doc: doc,
          act_type: act_type_tag
        })
      end

      mail(from: 'TodoLegal <suscripciones@todolegal.app>', to: @user.email, subject: 'Alertas Legales')

      $tracker.track(@user.id, 'Notifications email', {
        'email_sent_at' => Date.today.to_s,
        'location' => "Notifications mailer"
      })

      #checks if user has a history, if it does, schedules a new job
      if @user_notifications_history
        job = MailUserPreferencesJob.set(wait: @user_preferences.mail_frequency.days).perform_later(@user)
        @user_preferences.job_id = job.provider_job_id
        @user_preferences.save
      end
  end

end
