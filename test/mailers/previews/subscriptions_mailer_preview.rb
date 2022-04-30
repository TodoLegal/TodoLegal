# Preview all emails at http://localhost:3000/rails/mailers/subscriptions_mailer
class SubscriptionsMailerPreview < ActionMailer::Preview
  def refer
    SubscriptionsMailer.refer(User.first, User.first.email)
  end
  def welcome_pro_user
    SubscriptionsMailer.welcome_pro_user(User.first)
  end
  def free_trial_end
    SubscriptionsMailer.free_trial_end(User.first)
  end
  def welcome_basic_user
    SubscriptionsMailer.welcome_basic_user(User.first)
  end
  def discount_coupon
    SubscriptionsMailer.discount_coupon(User.first)
  end
end
