class NotificationsMailer < ApplicationMailer
  default from: 'TodoLegal <suscripciones@todolegal.app>'
  helper ApplicationHelper

  def is_a_valid_email?(email)
    #email_regex = %r{/\b[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}\z/}xi # Case insensitive
    #(email =~ email_regex)
  end

  def user_preferences_mail(user, notif_arr, justOnce) 
      @user = user
      @user_preferences = UsersPreference.find_by(user_id: @user.id)
      @last_email_sent_date = UserNotificationsHistory.find_by(user_id: @user.id)
      @last_email_sent_date = @last_email_sent_date ? @last_email_sent_date.mail_sent_at : DateTime.now 
      @documents_to_send = []

      # @docs_array = []
      # @tags_array = [1, 3, 5, 17, 51]

      # @tema_tag_id = TagType.find_by(name: "tema").id
      # @materia_tag_id = TagType.find_by(name: "materia").id

      # docs = []
      # @tags_array.each do |tag|
      #   temp = Document.joins(:document_tags).where('publication_date > ?',(Date.today - 3000.day).to_datetime).where('document_tags.tag_id'=> tag).select(:tag_id, :id, :name, :issue_id, :publication_number, :publication_date, :description, :url)
        
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

      # if DateTime.now >= (@last_email_sent_date + @user_preferences.mail_frequency.days) && !justOnce
      if !justOnce
        MailUserPreferencesJob.set(wait: 5.minutes).perform_later(@user, justOnce: false)
      end
      # end
  end

end
