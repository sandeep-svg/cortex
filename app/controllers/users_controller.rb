class UsersController < ApplicationController
  before_action :require_admin
  before_action :set_user, only: :update

  def index
    @users = User.order(:email_address)
  end

  # The only thing admins can change about another user is their role.
  def update
    if @user == current_user
      redirect_to users_path, alert: "You can't change your own role — ask another admin."
    elsif @user.update(role_params)
      redirect_to users_path, notice: "#{@user.email_address} is now #{@user.role}."
    else
      redirect_to users_path, alert: @user.errors.full_messages.join(", ")
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def role_params
    params.require(:user).permit(:role)
  end
end
