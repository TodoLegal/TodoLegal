class BillingController < ApplicationController
  layout 'billing'
  before_action :user_plan_is_inactive!, only: [:charge, :checkout]
  
  def checkout
    if !current_user
      respond_to do |format|
        format.html { redirect_to root_path, notice: I18n.t(:login_required) }
      end
      return
    end

    @is_monthly = params[:is_monthly]
    @is_onboarding = params[:is_onboarding]
    @go_to_law = params["go_to_law"]
  end

  def charge
    customer = Stripe::Customer.create(email: current_user.email, source: params["stripeToken"])
    if params["is_monthly"] == "true"
      subscription = Stripe::Subscription.create({
        customer: customer.id,
        items: [{
          price: STRIPE_MONTH_SUBSCRIPTION_PRICE,
        }]
      })
    else
      subscription = Stripe::Subscription.create({
        customer: customer.id,
        items: [{
          price: STRIPE_YEAR_SUBSCRIPTION_PRICE
        }],
        coupon: STRIPE_LAUNCH_COUPON_ID
      })
    end

    user = User.find_by_email(params["email"])
    user.stripe_customer_id = customer.id
    user.save

    respond_to do |format|
      if params["go_to_law"].blank?
        format.html { redirect_to root_path, notice: I18n.t(:charge_complete) }
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
    redirect_to portal_session.url
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