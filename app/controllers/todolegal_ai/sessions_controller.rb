# frozen_string_literal: true

module TodolegalAi
  class SessionsController < Devise::SessionsController
    include TodolegalAiAuth

    before_action :store_todolegal_ai_return_to, only: [:new]

    def new
      self.resource = resource_class.new(sign_in_params)
      clean_up_passwords(resource)
      yield resource if block_given?
      render 'todolegal_ai/sessions/new'
    end

    # Override Devise create to validate source_app after authentication.
    # Same pattern as Devise's Confirmable — authenticate first, then check eligibility.
    def create
      super do |user|
        if user.persisted? && user.source_app != 'todolegal_ai'
          sign_out(user)
          flash.discard
          flash[:alert] = "Esta cuenta no tiene acceso a TodoLegal AI."
          redirect_to todolegal_ai_sign_in_path and return
        end
      end
    end

    protected

    # After successful sign-in, return to the stored OAuth authorize URL
    # (or fall back to root).
    def after_sign_in_path_for(_resource)
      safe_return_to(stored_todolegal_ai_return_to) || root_path
    end
  end
end
