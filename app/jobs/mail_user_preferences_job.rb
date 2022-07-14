class MailUserPreferencesJob < ApplicationJob
  queue_as :default

  def perform(user)
        @tags = []
        @user_preferences = UsersPreference.find_by(user_id: user.id)
        documents_tags  =  []
        uniq_documents_tags = []
        notification_history = []        
        @all_notifications_history = UserNotificationsHistory.select("documents_ids").where(user_id: user.id)
        # @last_email_sent_date = UserNotificationsHistory.select("mail_sent_at").order(mail_sent_at: :desc).limit(1).find_by(user_id: user.id).mail_sent_at
        @docs_to_be_sent = []
        @user_notification_history = nil

      #get all the documents that contains the tags the user has selected
      @user_preferences.user_preference_tags.each do |tag|
        temp = nil
        temp = Document.joins(:document_tags).select(:id, :tag_id,  :name, :issue_id, :publication_number, :publication_date, :description, :url).where('publication_date > ?',(Date.today - 1000.day).to_datetime).where('document_tags.tag_id'=> tag)

        if temp.blank? != true
          temp.each do |doc|
            documents_tags << temp
          end
        end

      end

      #sort the queried documents from oldest to most recent
      documents_tags = documents_tags.flatten
      documents_tags = documents_tags.sort_by{|item| item.publication_date }
      uniq_documents_tags = documents_tags.uniq{ |document| [document.id] }


      #discard documents that had been sent in previous emails, using the user's notifications history
      if @all_notifications_history.count > 0 
        @all_notifications_history.pluck(:documents_ids).each do |ida|
          uniq_documents_tags.each do |idb|
            if !ida.include?(idb.id)
              notification_history.push(idb)
            end
          end
        end
      else
        notification_history = uniq_documents_tags
      end

      #limit the documents array to be 25 or less documents
      if notification_history.length >= 24 
        cont = 0
        notification_history.each do |id|
          if cont <= 24
            @docs_to_be_sent.push(id)
            cont=cont+1
          end
        end
      else
        @docs_to_be_sent = notification_history
      end  
      
      @docs_to_be_sent = @docs_to_be_sent.uniq

      #Send Routine
      if @docs_to_be_sent.blank? != true
        NotificationsMailer.user_preferences_mail(user, @docs_to_be_sent).deliver
        @user_notifications_history = UserNotificationsHistory.create(user_id: user.id ,mail_sent_at: DateTime.now, documents_ids: @docs_to_be_sent.collect(&:id) )
        @user_notifications_history.save
      end
      
  end
end
