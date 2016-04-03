class GameAttendee < ActiveRecord::Base
  belongs_to :game
  belongs_to :user

  after_create :reminder, unless: Proc.new{self.user.text_reminder}

  @@REMINDER_TIME = 60.minutes # minutes before appointment

  # Notify our game attendee X minutes before the appointment time
  def reminder
    @twilio_number = Rails.application.secrets.twilio_number
    @client = Twilio::REST::Client.new Rails.application.secrets.twilio_account_sid, Rails.application.secrets.twilio_auth_token
    time_str = ((self.game.date).localtime).strftime("%I:%M%p on %b. %d, %Y")
    reminder = "#{self.user.name} you have a #{self.game.sport_name} game at #{time_str}, at #{self.game.location}. To view the game, #{ENV['HOST_URL']}games/#{self.game.id}"
    message = @client.account.messages.create(
      :from => @twilio_number,
      :to => self.user.phone,
      :body => reminder,
    )
    puts message.to
  end

  def when_to_run
    self.game.date - @@REMINDER_TIME
  end

  handle_asynchronously :reminder, :run_at => Proc.new { |i| i.when_to_run }
end