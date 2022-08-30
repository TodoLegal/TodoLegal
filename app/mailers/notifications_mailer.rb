class NotificationsMailer < ApplicationMailer
  default from: 'TodoLegal <suscripciones@todolegal.app>'
  helper ApplicationHelper

  def is_a_valid_email?(email)
    #email_regex = %r{/\b[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}\z/}xi # Case insensitive
    #(email =~ email_regex)
  end

  def user_preferences_mail(user, notif_arr) 
      @user = user
    # @user = User.find_by(id: 31)
      @user_preferences = UsersPreference.find_by(user_id: @user.id)
      @user_notifications_history = UserNotificationsHistory.find_by(user_id: @user.id)
      @documents_to_send = []
      @issuer_documents = []


      # @docs_array = []
      # @tags_array = [1, 123, 3, 5, 165, 17, 130 ]

      # @tema_tag_id = TagType.find_by(name: "tema").id
      # @materia_tag_id = TagType.find_by(name: "materia").id

      # docs = []
      # @tags_array.each do |tag|
      #   if tag == 123 || tag == 165 || tag == 130
      #     temp = Document.joins(:issuer_document_tags).where('publication_date > ?',(Date.today - 5000.day).to_datetime).where('issuer_document_tags.tag_id'=> tag).select(:tag_id, :id, :name, :issue_id, :publication_number, :publication_date, :description, :url)
      #   else
      #     temp = Document.joins(:document_tags).where('publication_date > ?',(Date.today - 5000.day).to_datetime).where('document_tags.tag_id'=> tag).select(:tag_id, :id, :name, :issue_id, :publication_number, :publication_date, :description, :url)
      #   end

      #   if temp.length > 0
      #     temp.each do | doc |
      #       docs.push( doc )
      #     end
      #   end

      # end

      # docs.each do |doc|
      #   @docs_array.push(doc)
      # end

      # docs = @docs_array.sort_by{|item| item.tag_id }
      # docs = docs.uniq

      docs = notif_arr.sort_by{|item| item.tag_id }
      current_tag_name = ""
      current_tag_type = ""
      temp_docs = []

      docs.each do |doc|
        tag = Tag.find_by(id: doc.tag_id)
        tag_type = TagType.find_by(id: tag.tag_type_id)
        if tag.name != current_tag_name || doc == docs.last

          if doc == docs.last
            if tag.name != current_tag_name
              if current_tag_type == "Institución"
                @issuer_documents.push({
                  "tag_name": current_tag_name == "" ? tag.name : current_tag_name,
                  "tag_type": current_tag_type == "" ? tag_type.name : current_tag_type,
                  "documents": temp_docs
                })
              else
                @documents_to_send.push({
                  "tag_name": current_tag_name == "" ? tag.name : current_tag_name,
                  "tag_type": current_tag_type == "" ? tag_type.name : current_tag_type,
                  "documents": temp_docs
                })
              end
              temp_docs = []
            end
            temp_docs.push(doc)
            current_tag_type = tag_type.name
            current_tag_name = tag.name
          end

          if temp_docs.length > 0
            if current_tag_type == "Institución"
              @issuer_documents.push({
                "tag_name": current_tag_name == "" ? tag.name : current_tag_name,
                "tag_type": current_tag_type == "" ? tag_type.name : current_tag_type,
                "documents": temp_docs
              })
            else
              @documents_to_send.push({
                "tag_name": current_tag_name == "" ? tag.name : current_tag_name,
                "tag_type": current_tag_type == "" ? tag_type.name : current_tag_type,
                "documents": temp_docs
              })
            end
            temp_docs = []
          end
          current_tag_type = tag_type.name
          current_tag_name = tag.name
        end
        temp_docs.push(doc)
      end

      @documents_to_send = @documents_to_send + @issuer_documents

      mail(from: 'TodoLegal <suscripciones@todolegal.app>', to: @user.email, subject: 'Notificaciones personalizadas.')

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
