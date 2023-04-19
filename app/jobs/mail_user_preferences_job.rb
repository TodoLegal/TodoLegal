class MailUserPreferencesJob < ApplicationJob
  queue_as :default
  include ApplicationHelper

  def perform(user)
    @user_preferences = UsersPreference.find_by(user_id: user.id)
    documents_tags  =  []
    uniq_documents_tags = []
    filtered_documents = []        
    @user_notifications_history = UserNotificationsHistory.find_by(user_id: user.id)
    @docs_to_be_sent = []
    @institution_tag_type = TagType.find_by(name: "Institución").id
    @mercantil_tag_id = Tag.find_by(name: "Mercantil").id

    #get all the documents that contains the tags the user has selected
    @user_preferences.user_preference_tags.each do |tag|
      temp = nil
      @current_tag = Tag.find_by(id: tag)

      #if tag is Institución type, query documents from issuers_document_tags table only
      if @current_tag && @current_tag.tag_type_id == @institution_tag_type
        temp = Document.joins(:issuer_document_tags).select(:id, :tag_id,  :name, :issue_id, :publication_number, :publication_date, :description, :url).where('publication_date > ?',(Date.today - 45.day).to_datetime).where('documents.updated_at <= ?', DateTime.now - 20.minutes).where('issuer_document_tags.tag_id'=> tag)
      else
        temp = Document.joins(:document_tags).select(:id, :tag_id,  :name, :issue_id, :publication_number, :publication_date, :description, :url).where('publication_date > ?',(Date.today - 45.day).to_datetime).where('documents.updated_at <= ?', DateTime.now - 20.minutes).where('document_tags.tag_id'=> tag)
      end

      #if tag is Mercantil, discard documents that are Marcas de Fabrica 
      if @current_tag.id == @mercantil_tag_id
        temp = temp.where("name NOT LIKE \'%Marcas de Fábrica%\'")
      end

      if temp.blank? != true
        temp.each do |doc|
            documents_tags << temp
        end
      end

    end

    #sort the queried documents from oldest to most recent
    documents_tags = documents_tags.flatten
    uniq_documents_tags = documents_tags.uniq{ |document| [document.id] }
    uniq_documents_tags = uniq_documents_tags.sort_by{|item| item.publication_date }


    #discard documents that had been sent in previous emails, using the user's notifications history
    if @user_notifications_history 
      uniq_documents_tags.each do |document|
        if !@user_notifications_history.documents_ids.include?(document.id)
          filtered_documents.push(document)
        end
      end
    else
      filtered_documents = uniq_documents_tags
    end

    #limit the documents array to be 25 or less documents
    if filtered_documents.length >= 25 
      cont = 0
      filtered_documents.each do |id|
        if cont <= 24
          @docs_to_be_sent.push(id)
          cont=cont+1
        end
      end
    else
      @docs_to_be_sent = filtered_documents
    end  
    
    @docs_to_be_sent = @docs_to_be_sent.uniq

    #Send Routine
    if can_access_documents(user) && @user_preferences.active_notifications
      if @docs_to_be_sent.blank? != true
        NotificationsMailer.user_preferences_mail(user, @docs_to_be_sent).deliver
        if @user_notifications_history
          @user_notifications_history.documents_ids = @user_notifications_history.documents_ids + @docs_to_be_sent.collect(&:id)
          @user_notifications_history.mail_sent_at = DateTime.now
          @user_notifications_history.save
        else
          @user_notifications_history = UserNotificationsHistory.create(user_id: user.id ,mail_sent_at: DateTime.now, documents_ids: @docs_to_be_sent.collect(&:id) )
          @user_notifications_history.save
        end
      else
        enqueue_new_job(user)
      end
    end
    
  end

  private

  def get_documents user
  end
end
