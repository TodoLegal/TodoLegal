class DocumentProcessingMailer < ApplicationMailer

  def document_processing_complete(user, document_link)
    @user = user
    @document_link = document_link
    mail(from: 'TodoLegal <suscripciones@todolegal.app>', to: @user.email, subject: 'Se ha completado el procesamiento del documento')
  end

end
