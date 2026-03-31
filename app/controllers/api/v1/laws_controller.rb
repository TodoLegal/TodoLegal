class Api::V1::LawsController < Api::V1::BaseController

  def get_law
    @law = Law.find_by_id(params[:id])
    get_raw_law
    render json: { "law": @law, "stream": @stream }
  end
end