# frozen_string_literal: true

module TodolegalAi
  class RegistrationsController < Devise::RegistrationsController
    include TodolegalAiAuth

    before_action :store_todolegal_ai_return_to, only: [:new]
    before_action :check_self_registration, only: [:new, :create]

    def new
      build_resource
      yield resource if block_given?
      render 'todolegal_ai/registrations/new'
    end

    protected

    def after_sign_up_path_for(_resource)
      safe_return_to(stored_todolegal_ai_return_to) || root_path
    end

    private

    def check_self_registration
      unless self_registration_enabled?
        render 'todolegal_ai/registrations/invite_only', status: :forbidden
      end
    end

    def sign_up_params
      params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
    end
  end
end
