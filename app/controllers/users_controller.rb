class UsersController < ApplicationController


  def index
    @users = User.all
  end

  def edit
    @user = User.find params[:id]
    if @user != current_user
      redirect_to :back
    end
  end

  def show
    @user = User.find params[:id]
  end

  def update
    @user = User.find params[:id]
    if @user.update_attributes(user_params)
      redirect_to :back
    else
      redirect_to :back
    end
  end

  def destroy
    @user = User.find params[:id]
  end

  private
  def user_params
    params.require(:user).permit(:longitude,:latitude, :location, :phone, :name, :bio, :text_reminder)
  end
end
