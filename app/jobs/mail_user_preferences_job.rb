class MailUserPreferencesJob < ApplicationJob
  queue_as :mailers

  def perform(user)
        @tags = []
        @user_preferences = UsersPreference.find_by(user_id: user.id)
        #@preference_tags = UsersPreferencesTag.joins(:tag).where(users_preferences_tags: {is_tag_available: true}).select(:tag_id, :name)
        documents_tags  =  []
        uniq_documents_tags = []
        #@documents_to_save = UserNotificationsHistory.new(user_notifications_history_params)
        @current_id = 0
        notification_history = []        
        @all_notifications_history = UserNotificationsHistory.select("documents_ids").where(user_id: user.id)
        @ids_to_be_sent = []
        @user_notification_history = nil

      @user_preferences.user_preference_tags.each do |tag|
        documents_tags.push(Document.joins(:document_tags).where('publication_date > ?',  (Date.today - 45.day).to_datetime).where('document_tags.tag_id'=> tag).pluck(:document_id)).flatten
      end

      documents_tags = documents_tags.flatten

      uniq_documents_tags = documents_tags.uniq

      uniq_documents_tags.flatten

      if uniq_documents_tags.length >= 24 
          cont = 0
        uniq_documents_tags.each do |id|
          if cont <= 24
            notification_history.push(id)
            cont=cont+1
          end
        end
      else
        notification_history = uniq_documents_tags
      end

      notification_history = notification_history.flatten
      @notification_history_final = notification_history
       
      @all_notifications_history.pluck(:documents_ids).each do |ida|
        @notification_history_final.each do |idb|
          if ida != idb || ida.documents_ids.blank? == false
            @ids_to_be_sent.push(idb)
          end
        end
      end
      
      @ids_to_be_sent=@ids_to_be_sent.uniq

      @user_notifications_history = UserNotificationsHistory.create(user_id: current_user.id, mail_sent_at: DateTime.now, documents_ids: @ids_to_be_sent )
        NotificationsMailer.user_preferences_mail(user,@ids_to_be_sent).deliver_later(wait_until: 1.day.from_now)[]
      @user_notifications_history.save

  end
end
