class TokensController < ApplicationController
  before_filter :authenticate! 
  
  def create
    token = get_token
    grant = get_grant
    token.add_grant(grant)
    render json: {username: current_user.name, token: token.to_jwt}
  end

  def get_token
    Twilio::Util::AccessToken.new(
      Rails.application.secrets.twilio_account_sid,
      Rails.application.secrets.twil_ipm_api_key_sid,
      Rails.application.secrets.twil_ipm_api_key_secret,
      3600, 
      current_user.name
    )
  end

  def get_grant 
    grant = Twilio::Util::AccessToken::IpMessagingGrant.new 
    grant.endpoint_id = "Chatty:#{current_user.name.gsub(" ", "_")}:browser"
    grant.service_sid = Rails.application.secrets.twil_ipm_service_sid
    grant
  end

  private 
  def authenticate!
    if !current_user
      redirect_to root_path
    end
  end
end
