OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, Rails.application.secrets.facebook_client_id, Rails.application.secrets.facebook_client_secret, 
    {
      info_fields: 'name,email,bio,birthday,age_range,about,first_name,last_name,locale,location',
      display: 'popup', 
      client_options: {
        ssl: {
          ca_file: Rails.root.join("cacert.pem").to_s
        }
      }
    }
end


