class BillingController < ApplicationController
  layout 'billing'
  
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
    customer = Stripe::Customer.create(email: params["email"], source: params["stripeToken"])
    subscription = Stripe::Subscription.create({
      customer: customer.id,
      items: [{
        price: STRIPE_PRODUCT_PRICE,
      }],
    })

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
end