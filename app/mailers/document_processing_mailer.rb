class DocumentProcessingMailer < ApplicationMailer

  def document_processing_complete(user, document_link, process_status)
    @user = user
    @document_link = document_link
    @process_status = process_status
    @subject = "Se ha completado el procesamiento del documento"
    @message = "El documento ha sido procesado con éxito."
    if @process_status != "success"
      @message = "Ha ocurrido un error al procesar el documento."
      @subject = "Error al procesar el documento"
    end
    mail(from: 'TodoLegal <suscripciones@todolegal.app>', to: @user.email, subject: @subject)
  end

end
