# Preview all emails at http://localhost:3000/rails/mailers/subscriptions_mailer
class SubscriptionsMailerPreview < ActionMailer::Preview
  def refer
    SubscriptionsMailer.refer(User.first, User.first.email)
  end
  def welcome_pro_user
    SubscriptionsMailer.welcome_pro_user(User.first)
  end
end
