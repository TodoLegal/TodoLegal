# frozen_string_literal: true

module TodolegalAi
  # Handles the "first-time password set" flow triggered by the admin welcome email.
  # Reuses Devise::PasswordsController — same secure one-time token mechanism,
  # different view and copy ("Activar cuenta" vs. "Restablecer contraseña").
  class InvitationsController < Devise::PasswordsController
    include TodolegalAiAuth

    # GET /todolegal-ai/set-password?reset_password_token=TOKEN
    def edit
      self.resource = resource_class.new
      set_minimum_password_length
      resource.reset_password_token = params[:reset_password_token]
      render 'todolegal_ai/invitations/set_password'
    end

    # PATCH /todolegal-ai/set-password
    # Delegates to Devise::PasswordsController#update which validates the token,
    # resets the password, and signs in the user.
    def update
      super
    end

    protected

    def after_resetting_password_path_for(_resource)
      safe_return_to(stored_todolegal_ai_return_to) || root_path
    end
  end
end
