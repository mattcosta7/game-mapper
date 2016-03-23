class GameAttendee < ActiveRecord::Base
  belongs_to :game
  belongs_to :user
end
