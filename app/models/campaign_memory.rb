class CampaignMemory < ApplicationRecord
  belongs_to :campaign

  TYPES = %w[event npc location quest consequence].freeze
  has_neighbors :embedding

  validates :memory_type, inclusion: { in: TYPES }
  validates :summary, presence: true
  validates :importance, inclusion: { in: 1..3 }

  scope :permanent, -> { where(importance: 3) }
  scope :by_type, ->(type) { where(memory_type: type) }
  scope :recent, -> { order(created_at: :desc) }
end
