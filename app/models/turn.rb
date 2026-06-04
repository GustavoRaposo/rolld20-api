class Turn < ApplicationRecord
  belongs_to :campaign
  belongs_to :character

  validates :turn_number, presence: true, uniqueness: { scope: :campaign_id }
  validates :player_action, :gm_narrative, presence: true

  def self.next_number_for(campaign_id)
    where(campaign_id: campaign_id).maximum(:turn_number).to_i + 1
  end
end
