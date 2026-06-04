class Campaign < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_many :characters,          dependent: :destroy
  has_many :turns,               dependent: :destroy
  has_many :campaign_memories,   dependent: :destroy
  has_many :world_lore_embeddings, dependent: :destroy

  enum :status, { setup: "setup", active: "active", archived: "archived" }, default: "setup"

  scope :owned_by,       ->(user) { where(owner_id: user.id) }
  scope :participated_by, ->(user) { where(id: user.characters.select(:campaign_id)) }
  scope :accessible_by,  ->(user) {
    owned_by(user).or(participated_by(user))
  }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :files_path, presence: true

  before_validation :generate_slug, on: :create

  def active?
    status == "active"
  end

  private

  def generate_slug
    if name.present?
      self.slug ||= "#{name.parameterize}-#{SecureRandom.hex(4)}"
      self.files_path ||= "storage/campaigns/#{slug}"
    end
  end
end
