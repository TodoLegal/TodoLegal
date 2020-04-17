# Preview all emails at http://localhost:3000/rails/mailers/subscriptions_mailer
class SubscriptionsMailerPreview < ActionMailer::Preview
  def subscribed_email
    SubscriptionsMailer.email_subscribed_email(EmailSubscription.first)
  end
end
