class NotificationsMailer < ApplicationMailer
  default from: 'TodoLegal <suscripciones@todolegal.app>'
  helper ApplicationHelper

  def is_a_valid_email?(email)
    #email_regex = %r{/\b[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}\z/}xi # Case insensitive
    #(email =~ email_regex)
  end

  def user_preferences_mail(user, notif_arr) 
      @user = User.find_by(email: "carlosvilla00896@gmail.com")
      @documents_to_send = []
      @tema_tag_id = TagType.find_by(name: "tema").id
      @materia_tag_id = TagType.find_by(name: "materia").id
      docs = DocumentTag.joins(:document).where(document_tags: {tag_id: @tema_tag_id }).or( DocumentTag.joins(:document).where(document_tags: {tag_id: @materia_tag_id }) ).select(:tag_id, :document_id, :name, :issue_id, :publication_number, :publication_date, :description)
      # docs = docs.group(:tag_id)
      docs = docs.order(tag_id: :asc)
      docs.each do |doc|
        @documents_to_send.push(doc)
      end
      #Controllers/ActiveStorageMailer have the jobs.
      mail(from: 'TodoLegal <suscripciones@todolegal.app>', to: @user.email, subject: 'Sus leyes importantes.')
  end

end
