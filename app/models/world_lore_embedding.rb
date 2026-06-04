class WorldLoreEmbedding < ApplicationRecord
  belongs_to :campaign

  has_neighbors :embedding

  validates :content, :chunk_id, presence: true
end
