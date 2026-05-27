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

    protected

    def after_resetting_password_path_for(_resource)
      safe_return_to(stored_todolegal_ai_return_to) || root_path
    end

    # Privacy by design: neutral response regardless of whether the email exists.
    # This prevents email enumeration through timing or response differences.
    def after_sending_reset_password_instructions_path_for(_resource_name)
      flash[:notice] = "Si tu correo está registrado, recibirás instrucciones para restablecer tu contraseña."
      todolegal_ai_sign_in_path
    end
  end
end
