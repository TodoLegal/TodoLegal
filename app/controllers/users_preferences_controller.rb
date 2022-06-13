class UsersPreferencesController < ApplicationController
  before_action :set_users_preference, only: %i[ show edit update destroy ]

  # GET /users_preferences or /users_preferences.json
  def index
    @tags = UsersPreferencesTag.where(is_tag_available: true)
    @users_preference = UsersPreference.new
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
        format.html { redirect_to users_preferences_url, notice: "Users preference was successfully created." }
        format.json { render :show, status: :created, location: @users_preference }
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
