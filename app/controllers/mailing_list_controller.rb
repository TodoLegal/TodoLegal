class MailingListController < ApplicationController
  require 'MailchimpMarketing'
  def addEmail
    client = MailchimpMarketing::Client.new()
    client.set_config({
      :api_key => ENV['MAILCHIMP_API_KEY'],
      :server => ENV['MAILCHIMP_DC']
    })
    response =
      client.lists.add_list_member(
        ENV['MAILCHIMP_UNIQUE_ID'], {email_address: params[:email],'status' => 'pending'})
    p response
    redirect_back fallback_location:"/" , notice: "Te has suscrito a la lista de Correo de TodoLegal exitosamente."
  rescue MailchimpMarketing::ApiError => e
    puts e
    if e.blank?
      
    else
      redirect_back fallback_location:"/" 
    end
  end
end
