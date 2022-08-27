class UsersPreferencesTagsController < ApplicationController
  before_action :set_users_preferences_tag, only: %i[ show edit update destroy ]
  before_action :authenticate_admin!, only: [:index, :show, :new, :edit, :create, :update, :destroy]

  # GET /users_preferences_tags or /users_preferences_tags.json
  def index
    @tema_tag_id = TagType.find_by(name: "Tema").id
    @materia_tag_id = TagType.find_by(name: "materia").id

    @preferences_tags = UsersPreferencesTag.new
    @users_preferences_tags = UsersPreferencesTag.all
    
    @all_tags = Tag.where(tag_type_id: @materia_tag_id).or(Tag.where(tag_type_id: @tema_tag_id))
    @issuer_tags = Tag.joins(:issuer_document_tags)
    @issuer_tags = @issuer_tags.uniq
    @all_tags = @all_tags + @issuer_tags

    #Get tags with the most documents associated to them
    @top_tags = DocumentTag.joins(:tag).where(tags: {tag_type_id: @tema_tag_id}).or( DocumentTag.joins(:tag).where(tags: {tag_type_id: @materia_tag_id}) )
    @top_tags = @top_tags.group(:name).count
    @top_tags = Hash[@top_tags.sort_by {|k, v| -v} [0..19]].to_h
  end

  # GET /users_preferences_tags/1 or /users_preferences_tags/1.json
  def show
    if params[:users_preferences_tag] && params[:is_tag_available]
      @tag = UsersPreferencesTag.find_by_id(params[:users_preferences_tag].to_i)
      @tag.is_tag_available = params[:is_tag_available]
      @tag.save
    end
    redirect_to users_preferences_tags_url
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
        format.html { redirect_to users_preferences_tags_url, notice: "Users preferences tag was successfully created." }
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
        format.html { redirect_to users_preferences_tags_url, notice: "Users preferences tag was successfully updated." }
        format.json { render :show, status: :ok, location: @users_preferences_tag }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: users_preferences_tags_url.errors, status: :unprocessable_entity }
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
      params.require(:users_preferences_tag).permit(:tag_id, :is_tag_available)
    end
end
