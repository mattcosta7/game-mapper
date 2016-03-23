class User < ActiveRecord::Base
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      puts auth.inspect
      puts auth.info.inspect
      puts auth.extra.inspect
      puts auth.extra.raw_info.inspect
      user.provider = auth.provider 
      user.uid      = auth.uid
      user.name     = auth.info.name
      user.email    = auth.info.email
      user.first_name = auth.info.first_name
      user.last_name  = auth.info.last_name
      user.bio = auth.info.bio
      user.birthday = auth.info.birthday
      user.age_range = auth.info.age_range
      user.about  = auth.info.about
      user.location   = auth.info.location
      user.locale = auth.info.locale
      user.description = auth.info.description
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
end
