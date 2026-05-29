# Preview all emails at http://localhost:3000/rails/mailers/multi_app_devise_mailer
class MultiAppDeviseMailerPreview < ActionMailer::Preview
  def reset_password_instructions
    user = User.find_by(source_app: 'todolegal_ai') || User.first
    MultiAppDeviseMailer.reset_password_instructions(user, 'preview_token_456')
  end

  def welcome_instructions
    user = User.find_by(source_app: 'todolegal_ai') || User.first
    MultiAppDeviseMailer.welcome_instructions(user, 'preview_token_123')
  end

  def upgrade_instructions
    user = User.find_by(source_app: 'todolegal_ai') || User.first
    MultiAppDeviseMailer.upgrade_instructions(user)
  end
end
