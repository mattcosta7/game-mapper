class GameAttendeesController < ApplicationController
  
  def create
    @game = Game.find params[:id]
    @game.attendees << current_user
    respond_to do |format|
      format.js
      format.html
      format.json
    end
  end

  def destroy
    @ga = GameAttendee.where(game_id: params[:id], user_id: current_user).first
    @ga.destroy
    respond_to do |format|
      format.js
      format.html
      format.json
    end
  end

end
