class GamesController < ApplicationController

  def index
    if params[:date].present?
      time = params[:date].split('-')
      date = DateTime.new(time[0].to_i,time[1].to_i,time[2].to_i)
      @games = Game.where("DATE(date) = ? ",date).by_date
    else
      @games = Game.all.by_date.future
    end
    @game_json = []
    @games.each do |game|
      sport_name = {"sport_name" => game.sport_name}
      skill = {"skill" => game.skill}
      game = JSON::parse(game.to_json).merge(sport_name).merge(skill)
      @game_json << game
    end

    respond_to do |format|
      format.html
      format.json {render json: @game_json}
    end
  end

  def new
    @game = Game.new
  end

  def create
    @game = Game.new game_params
    if @game.save
      @game.attendees << current_user
      respond_to do |format|
        format.html {redirect_to games_path}
        format.js { render locals: {game: @game}}
      end
    else
      redirect_to :back
    end
  end

  def show
    @game = Game.find params[:id]
    attendees = {"attendees" => @game.attendees}
    sport_name = {"sport_name" => @game.sport_name}
    skill = {"skill" => @game.skill}
    cur_user = {current_user: current_user}
    @game_json = JSON::parse(@game.to_json).merge(attendees).merge(sport_name).merge(skill).merge(cur_user)
    respond_to do |format|
      format.html
      format.json {render json: @game_json}
    end
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
