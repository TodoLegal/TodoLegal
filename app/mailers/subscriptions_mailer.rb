class SubscriptionsMailer < ApplicationMailer
  default from: 'Todo Legal <suscripciones@todolegal.app>'

  def is_a_valid_email?(email)
    #email_regex = %r{/\b[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}\z/}xi # Case insensitive
    #(email =~ email_regex)
  end
  
  def email_subscribed_email(email_subscription)
    @email = email_subscription.email
    @security_key = email_subscription.security_key

    attachments.inline['subscription.png'] = File.read("#{Rails.root}/app/assets/images/subscription_mail.png")

    @confirmation_link = "https://todolegal.app/confirm_subscription?security_key=" + @security_key
    @unsubscribe_link = "https://todolegal.app/unsubscribe?security_key=" + @security_key
    #if is_a_valid_email?(@email)
      mail(from: 'TodoLegal <suscripciones@todolegal.app>', to: @email, subject: 'Confirmación de correo')
    #end
  end

  def email_confirmed_email(email_subscription)
    @email = email_subscription.email
    @security_key = email_subscription.security_key

    attachments.inline['confirmation.png'] = File.read("#{Rails.root}/app/assets/images/confirmation_mail.png")

    @confirmation_link = "https://todolegal.app/confirm_subscription?security_key=" + @security_key
    @unsubscribe_link = "https://todolegal.app/unsubscribe?security_key=" + @security_key
    #if is_a_valid_email?(@email)
      mail(from: 'TodoLegal <suscripciones@todolegal.app>', to: @email, subject: 'Descuento')
    #end
  end
end
