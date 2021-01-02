class SubscriptionsMailer < ApplicationMailer
  default from: 'TodoLegal <suscripciones@todolegal.app>'

  def is_a_valid_email?(email)
    #email_regex = %r{/\b[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}\z/}xi # Case insensitive
    #(email =~ email_regex)
  end

  def refer(referrer, email)
    @referrer_name = referrer.first_name
    if referrer.last_name
      @referrer_name += " "
      @referrer_name += referrer.last_name
    end
    mail(from: 'TodoLegal <suscripciones@todolegal.app>', to: email, subject: 'Te han invitado a TodoLegal')
  end

  def welcome_pro_user user
    @user = user
    # TODO: make this auto calculated again
    @rounded_all_document_count = 1130
    mail(from: 'TodoLegal <suscripciones@todolegal.app>', to: user.email, subject: 'Cuenta Pro')
  end
end
