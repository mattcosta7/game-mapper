class GamesController < ApplicationController

  def index
    if current_user
      @games = Game.future
    else
      @games = Game.all
    end
  end

  def new
    @game = Game.new
  end

  def create
    @game = Game.new game_params
    if @game.save
      redirect_to games_path
    else
      redirect_to :back
    end
  end

  def show
    @game = Game.find params[:id]
  end

  def edit
    @game = Game.find params[:id]
  end

  def update
    @game = Game.find params[:id]
    if @game.update_attributes(game_params)
      redirect_to :back
    else
      redirect_to :back
    end
  end

  def destroy
    @game = Game.find params[:id]
    if @game.destroy
      redirect_to games_path
    else
      redirect_to :back
    end
  end

  private
  def game_params
    params.require(:game).permit(:address, :city, :state, :sport, :skill_level, :date).merge(creator_id: current_user.id)
  end

end
