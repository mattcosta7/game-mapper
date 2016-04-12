class User < ActiveRecord::Base
  has_many :games_created, foreign_key: :creator_id, class_name: :Game, dependent: :destroy
  has_many :game_attendees
  has_many :games_attending, through: :game_attendees, source: :game
  
  before_validation :phone_check

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.provider = auth.provider 
      user.uid      = auth.uid
      user.name     = auth.info.name
      user.email    = auth.info.email
      user.first_name = auth.info.first_name
      user.last_name  = auth.info.last_name
      user.bio = auth.info.bio
      user.phone = auth.info.phone
      user.image = auth.info.image
      user.token = auth.credentials.token
      user.expires_at = Time.at(auth.credentials.expires_at)
      user.save!
    end
  end

  def profile_photo(size='normal')
    "http://graph.facebook.com/#{self.uid}/picture?type=#{size}"
  end


  def phone_check
    if self.phone
      @client = Twilio::REST::LookupsClient.new Rails.application.secrets.twilio_account_sid, Rails.application.secrets.twilio_auth_token
      begin
        response = @client.phone_numbers.get(self.phone) 
        self.phone = response.phone_number
        return true
      rescue => e 
        if e.code == 20404       
          return false
        else
          raise e
        end
      end
    end
  end
    
end
