# Turns raw embedding vectors from any provider into pgvector-friendly vectors.
#
# Design note: the `chunks.embedding` column is fixed at 3072 dimensions so it can
# hold output from any embedding model (OpenAI 1536/3072, Gemini 768/3072, Ollama
# 768/1024, ...). To make that safe we:
#   1. Normalize each vector to unit length
#   2. Zero-pad it to exactly 3072 dimensions
#
# Cosine similarity between two zero-padded unit vectors equals cosine similarity
# of the originals, so the search math stays exact no matter which model produced
# the embeddings.
class EmbeddingService
  VECTOR_DIM = 3072

  class << self
    # The provider used to embed documents + queries.
    def embedder
      Provider.active_embedding_provider
    end

    def embed(texts, provider: nil)
      provider ||= embedder
      raise "No provider with an embedding model is enabled. Configure one in the admin panel." unless provider

      client = provider.client
      vectors = client.respond_to?(:embed_many) ? client.embed_many(Array(texts)) : Array(texts).map { |t| client.embed(t) }

      if vectors.length != texts.length
        raise "Embedding provider #{provider.name} returned #{vectors.length} vectors for #{texts.length} texts"
      end

      vectors.each_with_index do |vector, index|
        raise embedding_error(provider, vector, index) if vector.nil? || vector.empty?
      end

      vectors.map { |vector| normalize_and_pad(vector) }
    end

    def query_vector(text, provider: nil)
      embed([ text ], provider: provider).first
    end

    def normalize_and_pad(vector)
      raise ArgumentError, "Cannot normalize an empty embedding vector" if vector.nil? || vector.empty?

      norm = Math.sqrt(vector.sum { |x| x.to_f * x.to_f })
      normalized = norm.positive? ? vector.map { |x| x.to_f / norm } : vector.map(&:to_f)
      normalized + [ 0.0 ] * (VECTOR_DIM - normalized.length)
    end

    def embedding_error(provider, vector, index)
      <<~MSG.strip
        Embedding provider #{provider.name} returned an empty vector for item #{index + 1}
        (model: #{provider.embedding_model || "not set"}). Check that the model exists on the provider.
      MSG
    end
  end
end
