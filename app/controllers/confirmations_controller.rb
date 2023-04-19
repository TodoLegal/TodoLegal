class ConfirmationsController < Devise::ConfirmationsController
  private
  def after_confirmation_path_for(resource_name, resource)
    sign_in(resource) # In case you want to sign in the user
    puts "Uses customized method confirmations_controller"
    "https://valid.todolegal.app"
  end
end