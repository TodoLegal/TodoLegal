class Api::V1::TagsController < ApplicationController
    protect_from_forgery with: :null_session
  
    def get_tags
      tag_type = nil
      @tags = []
      if !params[:type].blank?
        tag_type = TagType.where(name: params[:type])
        @tags = Tag.where(tag_type: tag_type)
      end
      render json: { "tags": @tags }
    end

    def get_preference_tags_list
      @tags = []
      @tags = UsersPreferencesTag.where(is_tag_available: true)

      render json: {"preference_tags_list": @tags}
    end
  end