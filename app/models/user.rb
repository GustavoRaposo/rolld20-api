class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :validatable, :jwt_authenticatable,
         jwt_revocation_strategy: JwtDenylist

  enum :role, { player: "player", admin: "admin" }, default: "player"

  has_many :campaigns, foreign_key: :owner_id
  has_many :characters

  def accessible_campaigns
    Campaign.accessible_by(self)
  end
end
