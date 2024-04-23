# Preview all emails at http://localhost:3000/rails/mailers/document_processing_mailer
class DocumentProcessingMailerPreview < ActionMailer::Preview
  def document_processing_complete
    DocumentProcessingMailer.document_processing_complete(User.first, "http://localhost:3000/admin/gazettes/#{Document.second.publication_number}", "error")
  end
end
