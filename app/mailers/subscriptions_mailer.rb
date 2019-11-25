class SubscriptionsMailer < ApplicationMailer
  default from: 'Todo Legal <rodil@todolegal.app>'

  def is_a_valid_email?(email)
    #email_regex = %r{/\b[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}\z/}xi # Case insensitive
    #(email =~ email_regex)
  end
  
  def email_subscribed_email(email_subscription)
    @email = email_subscription.email
    @security_key = email_subscription.security_key

    @confirmation_link = "https://todolegal.app/confirm_subscription?security_key=" + @security_key
    @unsubscribe_link = "https://todolegal.app/unsubscribe?security_key=" + @security_key
    #if is_a_valid_email?(@email)
      mail(from: 'Todo Legal <rodil@todolegal.app>', to: @email, subject: 'Completa tu subscripción a Todo Legal haciendo clic al siguiente enlace')
    #end
  end

  def email_confirmed_email(email_subscription)
    @email = email_subscription.email
    @security_key = email_subscription.security_key

    @confirmation_link = "https://todolegal.app/confirm_subscription?security_key=" + @security_key
    @unsubscribe_link = "https://todolegal.app/unsubscribe?security_key=" + @security_key
    #if is_a_valid_email?(@email)
      mail(from: 'Todo Legal <rodil@todolegal.app>', to: @email, subject: 'Bienvenido a Todo Legal! Haz completado tu subscripción.')
    #end
  end
end
