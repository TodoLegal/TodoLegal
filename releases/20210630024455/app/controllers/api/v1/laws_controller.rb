class Api::V1::LawsController < ApplicationController
  protect_from_forgery with: :null_session

  def get_law
    @law = Law.find_by_id(params[:id])
    get_raw_law
    render json: { "law": @law, "stream": @stream }
  end
end