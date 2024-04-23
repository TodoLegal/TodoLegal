class UsersDownloadMailer < ApplicationMailer

  def send_csv_email(user, csv_data)
    @user = user
    attachments['users.csv'] = { mime_type: 'text/csv', content: csv_data }
    mail(from: 'TodoLegal <suscripciones@todolegal.app>', to: user.email, subject: 'Usuarios descargados')
  end

end
