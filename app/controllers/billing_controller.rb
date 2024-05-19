class BillingController < ApplicationController
  layout 'billing'
  before_action :user_plan_is_inactive!, only: [:charge, :checkout]
  include ApplicationHelper
  
  
  def checkout
    if !current_user
      respond_to do |format|
        format.html { redirect_to root_path, notice: I18n.t(:login_required) }
      end
      return
    end
    if current_user
      $tracker.track(current_user.id, 'Checkout Visited', { })
    end

    @is_monthly = params[:is_monthly]
    @is_annually = params[:is_annually]
    @is_student = params[:is_student]
    @is_onboarding = params[:is_onboarding]
    @go_to_law = params["go_to_law"]
    @coupon = params["coupon"]

    @base_price_monthly = BASE_PRICE_MONTHLY
    @base_price_annually = BASE_PRICE_ANNUALLY
    @base_price_student = BASE_PRICE_STUDENT
    @monthly_price_annually = MONTHLY_PRICE_ANNUALLY
    @enterprise_price = ENTERPRISE_PRICE

    if params["invalid_card"] == "true"
      @stripe_backend_error = I18n.t(:invalid_card)
    end

    @is_coupon_valid = false
    @discount = 0
    @coupon_error_message = nil
    if !@coupon.blank?
      begin
        @coupon_data = Stripe::Coupon.retrieve(@coupon)
        @is_coupon_valid = @coupon_data.valid
        if !@is_coupon_valid
          @coupon_error_message = I18n.t(:stripe_coupon_invalid)
        end
        if @is_monthly
          @discount = @base_price_monthly * @coupon_data.percent_off/100.0
          @total_after_discount = @base_price_monthly - @discount
        else
          @discount = @base_price_annually * @coupon_data.percent_off/100.0
          @total_after_discount = @base_price_annually - @discount
        end
      rescue
        @coupon_error_message = I18n.t(:stripe_coupon_error)
      end
    end
  end

  def charge
    coupon = params["coupon"]
    begin
      customer = Stripe::Customer.create(email: current_user.email, source: params["stripeToken"])
    rescue
      respond_to do |format|
        redirect_path = checkout_path + "?invalid_card=true&"
        if !params["go_to_law"].blank?
          redirect_path += "go_to_law=" + params["go_to_law"] + "&"
        end
        if !params["is_monthly"].blank?
          redirect_path += "is_monthly=" + params["is_monthly"] + "&"
        end
        if !params["is_annually"].blank?
          redirect_path += "is_annually=" + params["is_annually"] + "&"
        end
        if !params["is_student"].blank?
          redirect_path += "is_student=" + params["is_student"] + "&"
        end
        redirect_path += "is_onboarding=true"
        format.html { redirect_to redirect_path }
      end
      return
    end
    if params["is_monthly"] == "true" && params["is_student"].blank?
      if coupon.blank?
        subscription = Stripe::Subscription.create({
          customer: customer.id,
          items: [{
            price: STRIPE_MONTH_SUBSCRIPTION_PRICE,
          }]
        })
        if current_user
          $tracker.track(current_user.id, 'Upgrade Plan', {
            'plan' => 'Pro',
            'payment' => 'Monthly',
            'coupon' => false
          })
        end
      else
        subscription = Stripe::Subscription.create({
          customer: customer.id,
          items: [{
            price: STRIPE_MONTH_SUBSCRIPTION_PRICE,
          }],
          coupon: coupon
        })
        if current_user
          $tracker.track(current_user.id, 'Upgrade Plan', {
            'plan' => 'Pro',
            'payment' => 'Monthly',
            'coupon' => true
          })
        end
      end
      if $discord_bot
        $discord_bot.send_message($discord_bot_channel_notifications, "Se ha registrado un usuario Pro por 1 mes :dancer:")
      end
      if ENV['MAILGUN_KEY']
        SubscriptionsMailer.welcome_pro_user(current_user).deliver
      end
    elsif params["is_annually"] == "true"
      if coupon.blank?
        subscription = Stripe::Subscription.create({
          customer: customer.id,
          items: [{
            price: STRIPE_YEAR_SUBSCRIPTION_PRICE
          }]
        })
        if current_user
          $tracker.track(current_user.id, 'Upgrade Plan', {
            'plan' => 'Pro',
            'payment' => 'Yearly',
            'coupon' => false
          })
        end
      else
        subscription = Stripe::Subscription.create({
          customer: customer.id,
          items: [{
            price: STRIPE_YEAR_SUBSCRIPTION_PRICE
          }],
          coupon: coupon
        })
        if current_user
          $tracker.track(current_user.id, 'Upgrade Plan', {
            'plan' => 'Pro',
            'payment' => 'Yearly',
            'coupon' => true
          })
        end
      end
      if $discord_bot
        $discord_bot.send_message($discord_bot_channel_notifications, "Se ha registrado un usuario Pro por 1 año :dancer:")
      end
      if ENV['MAILGUN_KEY']
        SubscriptionsMailer.welcome_pro_user(current_user).deliver
      end
    else
      if coupon.blank?
        subscription = Stripe::Subscription.create({
          customer: customer.id,
          items: [{
            price: STRIPE_STUDENT_SUBSCRIPTION_PRICE
          }]
        })
        if current_user
          $tracker.track(current_user.id, 'Upgrade Plan', {
            'plan' => 'Pro',
            'payment' => 'Student',
            'coupon' => false
          })
        end
      else
        subscription = Stripe::Subscription.create({
          customer: customer.id,
          items: [{
            price: STRIPE_STUDENT_SUBSCRIPTION_PRICE
          }],
          coupon: coupon
        })
        if current_user
          $tracker.track(current_user.id, 'Upgrade Plan', {
            'plan' => 'Pro',
            'payment' => 'Student',
            'coupon' => true
          })
        end
      end
      if $discord_bot
        $discord_bot.send_message($discord_bot_channel_notifications, "Se ha registrado un usuario Pro mensual estudiante :dancer:")
      end
      if ENV['MAILGUN_KEY']
        SubscriptionsMailer.welcome_pro_user(current_user).deliver
      end
    
    end

    user = User.find_by_email(params["email"])
    user.stripe_customer_id = customer.id
    user.save
    user_trial = UserTrial.find_by(user_id: user.id)
    
    if !user_trial
      user_trial = UserTrial.create(user_id: user.id, trial_start: DateTime.now, trial_end: DateTime.now + 2.weeks, active: false)
    end

    #delete notification email job if exists and enqueue a new job
    user_preferences = UsersPreference.find_by(user_id: user.id)
    if user_preferences
      delete_user_notifications_job(user_preferences.job_id)
      enqueue_new_job(user)
    end

    # if process_doorkeeper_redirect_to
    #   return
    # end

    respond_to do |format|
      if params["go_to_law"].blank?
        format.html { redirect_to confirm_email_view_path, notice: I18n.t(:charge_complete) }
      else
        format.html { redirect_to Law.find_by_id(params["go_to_law"]), notice: I18n.t(:charge_complete) }
      end
    end
  end

  def create_customer_portal_session
    portal_session = Stripe::BillingPortal::Session.create({
      customer: current_user.stripe_customer_id,
      return_url: 'https://todolegal.app/users/edit',
    })
    redirect_to portal_session.url, allow_other_host: true
  end

protected
  def user_plan_is_inactive!
    if current_user && current_user.stripe_customer_id
      begin
        customer = Stripe::Customer.retrieve(current_user.stripe_customer_id)
        if current_user_plan_is_active customer
          flash[:notice] = I18n.t(:plan_is_already_active)
          redirect_to root_path
        end
      rescue
      end
    end
  end
end
