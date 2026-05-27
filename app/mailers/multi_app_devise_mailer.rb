# frozen_string_literal: true

# Smart Devise mailer that routes to the correct branded template based on
# the user's `source_app` attribute. For `todolegal_ai` users it uses
# TodoLegal AI branded templates + correct reset/activation links.
# All other users fall through to the default Devise behavior.
class MultiAppDeviseMailer < Devise::Mailer
  helper :application

  def reset_password_instructions(record, token, opts = {})
    if record.source_app == 'todolegal_ai'
      opts[:template_path] = 'todolegal_ai/mailer'
      @reset_url = Rails.application.routes.url_helpers.todolegal_ai_reset_password_url(
        reset_password_token: token,
        host: Rails.application.config.action_mailer.default_url_options[:host]
      )
    end
    super
  end

  def welcome_instructions(record, token, opts = {})
    @user = record
    @set_password_url = Rails.application.routes.url_helpers.todolegal_ai_set_password_url(
      reset_password_token: token,
      host: Rails.application.config.action_mailer.default_url_options[:host]
    )
    opts[:template_path] = 'todolegal_ai/mailer'
    mail(
      to: record.email,
      subject: 'Bienvenido a TodoLegal AI',
      template_path: 'todolegal_ai/mailer',
      template_name: 'welcome_instructions'
    )
  end

  # Informational email for legacy users being upgraded to TodoLegal AI.
  # No password token — user keeps their existing credentials.
  def upgrade_instructions(record)
    @user = record
    @sign_in_url = Rails.application.routes.url_helpers.todolegal_ai_sign_in_url(
      host: Rails.application.config.action_mailer.default_url_options[:host]
    )
    mail(
      to: record.email,
      subject: 'Tu acceso exclusivo a TodoLegal AI',
      template_path: 'todolegal_ai/mailer',
      template_name: 'upgrade_instructions'
    )
  end
end
