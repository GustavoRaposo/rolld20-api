class Api::V1::Auth::UsersController < ApplicationController
  def me
    render json: {
      user: {
        id: current_user.id,
        email: current_user.email,
        role: current_user.role
      }
    }
  end
end
