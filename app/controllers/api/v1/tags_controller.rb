class Api::V1::TagsController < ApplicationController
    protect_from_forgery with: :null_session
  
    def get_tags
      tag_type = nil
      @tags = []
      if !params[:type].blank?
        tag_type = TagType.where(name: params[:type])
        if tag_type == "Institución"
          @tags = Tag.joins(:issuer_document_tags)
          @tags = @tags.uniq
        else 
          @tags = Tag.where(tag_type: tag_type)
        end
      end
      render json: { "tags": @tags }
    end

    def get_preference_tags_list
      @tags = []
      @preference_tags = UsersPreferencesTag.joins(:tag).where(users_preferences_tags: {is_tag_available: true}).select(:tag_id, :name, :tag_type_id)

      @preference_tags.each do |tag|
        tag_type_name = TagType.find_by(id: tag.tag_type_id).name
        @tags.push({"tag_id": tag.tag_id, "tag_name": tag.name, "tag_type": tag_type_name})
      end

      render json: {"preference_tags": @tags}
    end
  end