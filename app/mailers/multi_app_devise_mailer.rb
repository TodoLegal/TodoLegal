# frozen_string_literal: true

# Smart Devise mailer that routes to the correct branded template based on
# the user's `source_app` attribute. For `todolegal_ai` users it uses
# TodoLegal AI branded templates + correct reset/activation links.
# All other users fall through to the default Devise behavior.
class MultiAppDeviseMailer < Devise::Mailer
  helper :application
  layout 'todolegal_ai_mailer'

  def reset_password_instructions(record, token, opts = {})
    if record.source_app == 'todolegal_ai'
      opts[:template_path] = 'todolegal_ai/mailer'
      @reset_url = todolegal_ai_reset_password_url(
        reset_password_token: token,
        host: mailer_host
      )
    end
    super
  end

  def welcome_instructions(record, token, opts = {})
    @user = record
    @set_password_url = todolegal_ai_set_password_url(
      reset_password_token: token,
      host: mailer_host
    )
    opts[:template_path] = 'todolegal_ai/mailer'
    mail(
      from: Devise.mailer_sender,
      to: record.email,
      subject: 'Activa tu cuenta TodoLegal AI',
      template_path: 'todolegal_ai/mailer',
      template_name: 'welcome_instructions'
    )
  end

  # Informational email for legacy users being upgraded to TodoLegal AI.
  # No password token — user keeps their existing credentials.
  def upgrade_instructions(record)
    @user = record
    @sign_in_url = todolegal_ai_sign_in_url(host: mailer_host)
    mail(
      from: Devise.mailer_sender,
      to: record.email,
      subject: 'Tu acceso exclusivo a TodoLegal AI',
      template_path: 'todolegal_ai/mailer',
      template_name: 'upgrade_instructions'
    )
  end

  private

  def mailer_host
    # Use TODOLEGAL_BASE_URL (confirmed available in Passenger) and extract
    # just the host, falling back to the bare domain if not set.
    base = Rails.configuration.x.todolegal_base_url || "https://todolegal.app"
    URI.parse(base).host
  end
end
