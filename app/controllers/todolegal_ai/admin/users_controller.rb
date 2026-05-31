# frozen_string_literal: true

module TodolegalAi
  module Admin
    class UsersController < ApplicationController
      before_action :authenticate_admin!
      layout 'todolegal_ai'

      def index
        @users = User.where(source_app: 'todolegal_ai').order(created_at: :desc)
      end

      def new
        @user = User.new
      end

      def create
        existing = User.find_by(email: admin_user_params[:email]&.downcase&.strip)

        if existing.present?
          if existing.source_app == 'todolegal_ai'
            @user = User.new(admin_user_params)
            @user.errors.add(:email, 'ya está registrado en TodoLegal AI')
            render :new, status: :unprocessable_entity
            return
          end

          # Legacy user — show upgrade confirmation instead of failing on uniqueness
          @user = existing
          render :confirm_upgrade
          return
        end

        @user = User.new(admin_user_params)
        @user.source_app = 'todolegal_ai'
        # Assign a secure random password — user will set their real one via the welcome link.
        @user.password = SecureRandom.hex(20)
        @user.password_confirmation = @user.password
        @user.skip_confirmation! if @user.respond_to?(:skip_confirmation!)

        if @user.save
          assign_pro_permission(@user)
          token = @user.send(:set_reset_password_token)
          MultiAppDeviseMailer.welcome_instructions(@user, token).deliver_later

          redirect_to todolegal_ai_admin_user_path(@user),
            notice: "Cuenta creada. Se envió el correo de bienvenida a #{@user.email}."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def show
        @user = User.find(params[:id])
      end

      def resend_invite
        @user = User.find(params[:id])
        token = @user.send(:set_reset_password_token)
        MultiAppDeviseMailer.welcome_instructions(@user, token).deliver_later

        redirect_to todolegal_ai_admin_user_path(@user),
          notice: "Correo de bienvenida reenviado a #{@user.email}."
      end

      def upgrade
        @user = User.find(params[:id])
        @user.update!(source_app: 'todolegal_ai')
        assign_pro_permission(@user)

        if params[:reset_password] == 'true'
          token = @user.send(:set_reset_password_token)
          MultiAppDeviseMailer.welcome_instructions(@user, token).deliver_later
          notice = "Cuenta migrada. Se envió email con link de contraseña a #{@user.email}."
        else
          MultiAppDeviseMailer.upgrade_instructions(@user).deliver_later
          notice = "Cuenta migrada. Se envió email de bienvenida exclusivo a #{@user.email}."
        end

        redirect_to todolegal_ai_admin_user_path(@user), notice: notice
      end

      private

      def admin_user_params
        params.require(:user).permit(:first_name, :last_name, :email)
      end

      # Idempotently grants the Pro permission to a user.
      # Pro access lets TodoLegal AI users access legacy apps (todolegal.app, valid.todolegal.app)
      # without a Stripe subscription — same check as user_is_pro_api(user).
      def assign_pro_permission(user)
        pro_permission = Permission.find_or_create_by!(name: 'Pro')
        user.user_permissions.find_or_create_by!(permission: pro_permission)
      end

      def authenticate_admin!
        unless current_user&.admin?
          redirect_to root_path, alert: "Acceso no autorizado."
        end
      end
    end
  end
end
