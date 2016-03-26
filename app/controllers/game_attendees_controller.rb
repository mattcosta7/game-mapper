class GameAttendeesController < ApplicationController
  
  def create
    @game = Game.find params[:id]
    @game.attendees << current_user
    redirect_to @game
  end

  def destroy
    @ga = GameAttendee.where(game_id: params[:id], user_id: current_user).first
    @ga.destroy
    redirect_to :back
  end

end
