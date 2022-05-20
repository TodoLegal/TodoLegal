class UsersPreferencesTagsController < ApplicationController
  before_action :set_users_preferences_tag, only: %i[ show edit update destroy ]

  # GET /users_preferences_tags or /users_preferences_tags.json
  def index
    @users_preferences_tags = UsersPreferencesTag.all
  end

  # GET /users_preferences_tags/1 or /users_preferences_tags/1.json
  def show
  end

  # GET /users_preferences_tags/new
  def new
    @users_preferences_tag = UsersPreferencesTag.new
  end

  # GET /users_preferences_tags/1/edit
  def edit
  end

  # POST /users_preferences_tags or /users_preferences_tags.json
  def create
    @users_preferences_tag = UsersPreferencesTag.new(users_preferences_tag_params)

    respond_to do |format|
      if @users_preferences_tag.save
        format.html { redirect_to @users_preferences_tag, notice: "Users preferences tag was successfully created." }
        format.json { render :show, status: :created, location: @users_preferences_tag }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @users_preferences_tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users_preferences_tags/1 or /users_preferences_tags/1.json
  def update
    respond_to do |format|
      if @users_preferences_tag.update(users_preferences_tag_params)
        format.html { redirect_to @users_preferences_tag, notice: "Users preferences tag was successfully updated." }
        format.json { render :show, status: :ok, location: @users_preferences_tag }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @users_preferences_tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users_preferences_tags/1 or /users_preferences_tags/1.json
  def destroy
    @users_preferences_tag.destroy
    respond_to do |format|
      format.html { redirect_to users_preferences_tags_url, notice: "Users preferences tag was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_users_preferences_tag
      @users_preferences_tag = UsersPreferencesTag.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def users_preferences_tag_params
      params.require(:users_preferences_tag).permit(:tag_id)
    end
end
