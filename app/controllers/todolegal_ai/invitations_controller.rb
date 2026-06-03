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
    # After success, redirects to the frontend login URL if the env var is set
    # (using allow_other_host semantics via header override — the env var is a
    # trusted server-side constant, not user input, so no open-redirect risk).
    def update
      super
      return unless response.redirect? && resource.errors.empty?
      return unless (frontend_url = todolegal_ai_frontend_login_url)
      response.headers['Location'] = frontend_url
    end

    protected

    def after_resetting_password_path_for(_resource)
      root_path
    end
  end
end
