class Api::V1::Admin::UsersController < ApplicationController
  include AdminAuthorization

  def index
    users = User.order(:created_at)
    render json: users.map { |u| user_json(u) }
  end

  def update
    user = User.find(params[:id])
    return render_error "Cannot change your own role", status: :forbidden if user == current_user

    if user.update(user_params)
      render json: user_json(user)
    else
      render_error user.errors.full_messages.join(", ")
    end
  rescue ActiveRecord::RecordNotFound
    render_error "User not found", status: :not_found
  end

  private

  def user_params
    params.require(:user).permit(:role)
  end

  def user_json(user)
    {
      id:         user.id,
      email:      user.email,
      role:       user.role,
      created_at: user.created_at
    }
  end
end
