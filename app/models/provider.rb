class Provider < ApplicationRecord
  encrypts :api_key

  SLUGS = %w[openai anthropic gemini ollama].freeze

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true
  validates :slug, inclusion: { in: SLUGS }, allow_nil: true
  validate :only_one_active_provider, if: :active?

  scope :enabled, -> { where(enabled: true) }
  scope :ordered, -> { order(Arel.sql("active DESC, enabled DESC, name ASC")) }

  def self.active_provider
    find_by(active: true)
  end

  def self.active_chat_provider
    enabled.find_by(active: true)
  end

  # The provider used to embed chunks + queries.
  # Prefers the active provider if it can embed, otherwise the first enabled one that can.
  def self.active_embedding_provider
    providers = enabled.to_a
    providers.find { |p| p.active? && p.embedding_model? } ||
      providers.find(&:embedding_model?)
  end

  def chat_model?
    chat_model.present?
  end

  def embedding_model?
    embedding_model.present?
  end

  def ready?
    enabled? && chat_model? && (slug == "ollama" || api_key.present?)
  end

  def client
    Llm.build(self)
  end

  def mask_key
    return "" if api_key.blank?
    api_key.length > 8 ? "#{api_key.first(4)}…#{api_key.last(4)}" : "••••••••"
  end

  private

  def only_one_active_provider
    other = Provider.where(active: true).where.not(id: id)
    errors.add(:active, "is already set on #{other.first.name}") if other.exists?
  end
end
