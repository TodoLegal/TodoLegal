class UsersPreferencesController < ApplicationController
  before_action :set_users_preference, only: [:edit, :update, :destroy]
  include ApplicationHelper
  layout 'onboarding'
  # GET /users_preferences or /users_preferences.json
  def index
    @tags = UsersPreferencesTag.joins(:tag).where(users_preferences_tags: {is_tag_available: true}).select(:tag_id, :name)
    @users_preference = UsersPreference.new
    @reforma_tag_id = Tag.find_by(name: "Reformas y Derogaciones")&.id
    @tributario_tag_id = Tag.find_by(name: "Tributario")&.id
    @congreso_tag_id = Tag.find_by(name: "Congreso Nacional")&.id
    @default_selected_tags = []
    @default_selected_tags << @reforma_tag_id if @reforma_tag_id
    @default_selected_tags << @tributario_tag_id if @tributario_tag_id
    @default_selected_tags << @congreso_tag_id if @congreso_tag_id

    #onboarding parameters
    @redirect_to_valid = params[:redirect_to_valid]
    @go_to_law = params[:go_to_law]
    @is_onboarding = params[:is_onboarding]
    @is_monthly = params[:is_monthly]
    @is_annually = params[:is_annually]
    
    if current_user.blank?
      redirect_to "https://todolegal.app/users/sign_in", allow_other_host: true
    end

  end

  # GET /users_preferences/1 or /users_preferences/1.json
  def show
  end

  # GET /users_preferences/new
  def new
    @tags = UsersPreferencesTag.all
    @users_preference = UsersPreference.new
  end

  # GET /users_preferences/1/edit
  def edit
  end

  # POST /users_preferences or /users_preferences.json
  def create
    @users_preference = UsersPreference.new(users_preference_params)

    respond_to do |format|
      if @users_preference.save
        return_to_path = session[:return_to] if session[:return_to]
        if !params[:redirect_to_valid].blank?
          if return_to_path
            if current_user.confirmed_at?
              if process_doorkeeper_redirect_to
                return
              end
            else
              format.html { redirect_to confirm_email_view_path}
            end
          else
            format.html { redirect_to "https://valid.todolegal.app?user_just_signed_up=true", allow_other_host: true}
          end
        elsif !params[:is_monthly].blank?
          format.html { redirect_to checkout_url(is_onboarding:true, go_to_law: params[:go_to_law], is_monthly: params[:is_monthly]) }
          format.json { render :show, status: :created, location: @users_preference }
        elsif !params[:is_annually].blank?
          format.html { redirect_to checkout_url(is_onboarding:true, go_to_law: params[:go_to_law], is_annually: params[:is_annually]) }
          format.json { render :show, status: :created, location: @users_preference }
        else
          format.html { redirect_to "https://valid.todolegal.app?user_just_signed_up=false", allow_other_host: true}
        end

        mail_frequency = @users_preference.mail_frequency ? @users_preference.mail_frequency : 0
        
        if mail_frequency > 0
          # MailUserPreferencesJob.set(wait: 1.day).perform_later(current_user)
          job = MailUserPreferencesJob.set(wait: @users_preference.mail_frequency.days).perform_later(current_user)
          @users_preference.job_id = job.provider_job_id
          @users_preference.save
        end

        $tracker.track(current_user.id, 'Preferences edition', {
          'selected_tags' => get_tags_name(@users_preference.user_preference_tags),
          'selected_mail_frequency' => @users_preference.mail_frequency,
          'location' => "Onboarding"
        })

      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @users_preference.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users_preferences/1 or /users_preferences/1.json
  def update
    respond_to do |format|
      if @users_preference.update(users_preference_params)
        format.html { redirect_to users_preferences_url, notice: "Users preference was successfully updated." }
        format.json { render :show, status: :ok, location: @users_preference }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @users_preference.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users_preferences/1 or /users_preferences/1.json
  def destroy
    @users_preference.destroy
    respond_to do |format|
      format.html { redirect_to users_preferences_url, notice: "Users preference was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def skip_notifications
    if process_doorkeeper_redirect_to
      return
    end

    respond_to do |format|
      if @redirect_to_valid
        format.html { redirect_to "https://valid.todolegal.app?preferences=true", allow_other_host: true }
      else
        format.html { redirect_to "https://valid.todolegal.app?preferences=false", allow_other_host: true }
      end
    end

  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_users_preference
      @users_preference = UsersPreference.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def users_preference_params
      params.require(:users_preference).permit(:user_id, :mail_frequency, user_preference_tags: [])
    end
end
