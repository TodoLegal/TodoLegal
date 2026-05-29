# frozen_string_literal: true

module TodolegalAi
  class PasswordsController < Devise::PasswordsController
    include TodolegalAiAuth

    def new
      self.resource = resource_class.new
      render 'todolegal_ai/passwords/new'
    end

    def edit
      self.resource = resource_class.new
      set_minimum_password_length
      resource.reset_password_token = params[:reset_password_token]
      render 'todolegal_ai/passwords/edit'
    end

    # Privacy by design: always redirect with a neutral flash, regardless of
    # whether the email exists.  This is the Devise-recommended approach —
    # override `create` so both the success and failure paths produce an
    # identical response, eliminating the email-enumeration vector.
    def create
      resource_class.send_reset_password_instructions(resource_params)
      flash[:notice] = "Si tu correo está registrado, recibirás instrucciones para restablecer tu contraseña."
      redirect_to todolegal_ai_sign_in_path
    end

    protected

    def after_resetting_password_path_for(_resource)
      safe_return_to(stored_todolegal_ai_return_to) || root_path
    end
  end
end
