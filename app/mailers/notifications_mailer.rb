class NotificationsMailer < ApplicationMailer
  default from: 'TodoLegal <suscripciones@todolegal.app>'
  helper ApplicationHelper
  include ApplicationHelper

  def is_a_valid_email?(email)
    #email_regex = %r{/\b[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}\z/}xi # Case insensitive
    #(email =~ email_regex)
  end

  # This method is used to get the test data for the user preferences email.
  # It retrieves documents with specific tags and their associated issuer tags.
  # The tags are hardcoded for testing purposes.
  # The method returns an array of documents sorted by tag_id.
  #
  # @return [Array<Document>] An array of documents with their associated tags and issuer tags.
  def tags_test_data
    @docs_array = []
    @tags_array = [1, 3, 5, 17, 51]

    @tema_tag_id = TagType.find_by(name: "tema").id
    @materia_tag_id = TagType.find_by(name: "materia").id
    @institution_tag_type = TagType.find_by(name: "Institución").id

    docs = []
    @tags_array.each do |tag|
      # Get documents with regular tags
      temp = Document.joins(:document_tags)
        .where('publication_date > ?', (Date.today - 3000.day).to_datetime)
        .where('document_tags.tag_id' => tag)
        .select(:tag_id, :id, :name, :issue_id, :publication_number, :publication_date, :description, :url)
        
      if temp.length > 0
        temp.each do |doc|
          # Get the document with associated issuer tags
          full_doc = Document.includes(:issuer_document_tags).find(doc.id)
          
          # Get issuer tags for the document
          issuer_tags = full_doc.issuer_document_tags.map do |idt|
            Tag.find_by(id: idt.tag_id)&.name
          end.compact
          
          # Add issuer tags as an attribute to the document
          doc.instance_variable_set(:@issuer_tags, issuer_tags)
          doc.define_singleton_method(:issuer_tags) { @issuer_tags }
          
          docs.push(doc)
        end
      end
    end

    docs = docs.uniq{|document| document.id}
    sorted_docs = docs.sort_by{|item| item.tag_id }
    
    return sorted_docs
  end

  def remaining_trial user
    user_trial = user.user_trial

    if !user_trial && current_user_type_api(user) != "pro"
      user_trial = UserTrial.create(user_id: user.id, trial_start: DateTime.now, trial_end: DateTime.now + 2.weeks, active: true)
      SubscriptionsMailer.free_trial_end(user).deliver_later(wait_until: user_trial.trial_end - 1.days)
      NotificationsMailer.cancel_notifications(user).deliver_later(wait_until: user_trial.trial_end)
    end

    return remaining_free_trial_time(user)
  end

  # /rails/mailers
  # This method sends an email to the user with their preferences and notifications.
  def user_preferences_mail(user, notif_arr) 
      @user = user
      @user_preferences = UsersPreference.find_by(user_id: @user.id)
      @user_notifications_history = UserNotificationsHistory.find_by(user_id: @user.id)
      @documents_to_send = []
      @remaining_free_trial_time = remaining_trial(@user)
      @user_type = current_user_type_api(@user)
      
      #change this line to get data from tags_test_data method when testing
      docs = notif_arr.sort_by{|item| item.tag_id}

      current_tag_name = ""
      temp_docs = []

      @act_type_tag = TagType.find_by(name: "Tipo de Acto")
      
      docs.each do |doc|
        tag = Tag.find_by(id: doc.tag_id)

        act_type_tag = nil

        #obtains the Tipo de Acto tag from each document
        act_type_tag = Tag.joins(:document_tags).where( document_tags: {document_id: doc.id}).where(tags: {tag_type_id: @act_type_tag.id})
        act_type_tag = act_type_tag.first ? act_type_tag.first.name : nil

        # Get issuer tags if available
        issuer_tags = doc.respond_to?(:issuer_tags) ? doc.issuer_tags : []

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
              act_type: act_type_tag,
              issuer_tags: issuer_tags
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
          act_type: act_type_tag,
          issuer_tags: issuer_tags
        })
      end

      mail(from: 'TodoLegal <suscripciones@todolegal.app>', to: @user.email, subject: 'Alertas Legales')

      $tracker.track(@user.id, 'Notifications email', {
        'email_sent_at' => Date.today.to_s,
        'location' => "Notifications mailer"
      })

      enqueue_new_job(@user)
  end

  def pro_without_active_notifications user
    @user = user
    mail(from: 'TodoLegal <suscripciones@todolegal.app>', to: @user.email, subject: 'Recibe alertas personalizadas en tu correo electrónico')
  end

  def basic_without_active_notifications user
    @user = user
    mail(from: 'TodoLegal <suscripciones@todolegal.app>', to: @user.email, subject: 'Activación de notificaciones personalizadas')
  end

  def basic_with_active_notifications user
    @user = user
    mail(from: 'TodoLegal <suscripciones@todolegal.app>', to: @user.email, subject: 'Activación de notificaciones personalizadas')
  end

  def cancel_notifications user
    @user = user

    if current_user_type_api(user) != "pro"
      mail(from: 'TodoLegal <suscripciones@todolegal.app>', to: @user.email, subject: '¿Quieres seguir recibiendo notificaciones personalizadas?')
    end

    user_trial = @user.user_trial
    user_trial.active = false
    user_trial.save
  end

end
