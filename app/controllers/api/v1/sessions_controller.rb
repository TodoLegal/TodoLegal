class Api::V1::SessionsController < Devise::SessionsController
  #skip_before_action :verify_signed_out_user, only[:destroy]
  protect_from_forgery with: :null_session
  include ApplicationHelper
  before_action :doorkeeper_authorize!, only: [:me]

  def create
    user = warden.authenticate!({user: params[:user]})
    sign_in(resource_name, user)

    current_user.authentication_token = nil
    current_user.save

    respond_to do |format|
      format.json do
        render json: {
          user: current_user
        }
      end
    end
  end

  def destroy
    respond_to do |format|
      user = User.find_by authentication_token: params[:authentication_token]
      format.json do
        if user
          user.authentication_token = nil
          user.save
          sign_out(user)
          render json: {'message': 'You are now logged out.'}, status: :ok
        else
          render json: {'error': 'Invalid authentication token.'}, status: :unprocesable_entity
        end
      end
    end
  end

  def me
    user = User.find_by_id(doorkeeper_token.resource_owner_id)
    customer = Stripe::Customer.retrieve(user.stripe_customer_id)
    current_user_type = "not logged"
    if current_user_plan_is_active customer
      current_user_type = "basic"
    else
      current_user_type = "pro"
    end
    render json: {"document": json_document,
      "tags": get_document_tags,
      "related_documents": get_related_documents,
      "downloads": user_document_visit_tracker.visits,
      "can_access": can_access_document,
      "user_type": current_user_type
    }
  end
end