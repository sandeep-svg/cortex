class Chunk < ApplicationRecord
  has_neighbors :embedding

  belongs_to :document

  validates :content, presence: true

  # Cosine similarity search over the padded embeddings.
  # The gem exposes each row's distance as `neighbor_distance` (1 - cosine similarity).
  def self.nearest(embedding, limit: 6)
    nearest_neighbors(:embedding, embedding, distance: "cosine").limit(limit)
  end
end
