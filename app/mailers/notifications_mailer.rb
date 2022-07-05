class NotificationsMailer < ApplicationMailer
  default from: 'TodoLegal <suscripciones@todolegal.app>'
  helper ApplicationHelper

  def is_a_valid_email?(email)
    #email_regex = %r{/\b[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}\z/}xi # Case insensitive
    #(email =~ email_regex)
  end

  def user_preferences_mail(user, notif_arr) 
      @user = User.find_by(email: "carlosvilla00896@gmail.com")

      @tema_tag_id = TagType.find_by(name: "tema").id
      @materia_tag_id = TagType.find_by(name: "materia").id
      docs = Document.joins(:document_tags).select(:tag_id, :document_id, :name, :issue_id, :publication_number, :publication_date, :description)

      docs = docs.order(tag_id: :asc)
      @documents_to_send = []
      current_tag_name = ""
      temp_docs = []

      docs.each do |doc|
        tag_name = Tag.find_by(id: doc.tag_id).name
        if tag_name != current_tag_name
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
      #Controllers/ActiveStorageMailer have the jobs.
      mail(from: 'TodoLegal <suscripciones@todolegal.app>', to: @user.email, subject: 'Notificaciones personalizadas.')
  end

end
