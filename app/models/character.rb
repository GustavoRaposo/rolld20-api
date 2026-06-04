class Character < ApplicationRecord
  belongs_to :campaign
  belongs_to :user
  has_many :turns, dependent: :nullify

  CLASSES = %w[warrior mage rogue].freeze
  XP_FOR_LEVEL = ->(n) { 50 * n * (n - 1) }

  validates :name, presence: true
  validates :character_class, inclusion: { in: CLASSES }
  validates :level, numericality: { in: 1..10 }
  validates :files_path, presence: true

  before_validation :set_files_path, on: :create

  def xp_for_next_level
    return nil if level >= 10
    XP_FOR_LEVEL.call(level + 1)
  end

  def level_up_available?
    next_xp = xp_for_next_level
    next_xp && current_xp >= next_xp
  end

  private

  def set_files_path
    self.files_path ||= "storage/campaigns/#{campaign&.slug}/characters/#{SecureRandom.hex(4)}"
  end
end
