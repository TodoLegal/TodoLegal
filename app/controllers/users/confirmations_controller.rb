# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  include Devise::Controllers::Helpers
  # GET /resource/confirmation/new
  # def new
  #   super
  # end

  # POST /resource/confirmation
  def create
    super
    if @email
      @first_name = User.find_by_email(@email).first_name
    end
  end

  # def after_confirmation_path_for(resource_name, resource)
  #   # Customize the redirect URL here
  #   "https://valid.todolegal.app"
  # end

  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      set_flash_message!(:notice, :confirmed)
      respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource_name, resource) }
    else
      #respond_with_navigational(resource.errors, status: :unprocessable_entity){ render :new }
      set_flash_message!(:notice, :already_confirmed)
      respond_with_navigational(resource){ redirect_to '/' }
    end
  end


  # GET /resource/confirmation?confirmation_token=abcdef
  # def show
  #   super
  # end

  # protected

  # The path used after resending confirmation instructions.
  # def after_resending_confirmation_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  # The path used after confirmation.
  # def after_confirmation_path_for(resource_name, resource)
  #   super(resource_name, resource)
  # end
end
