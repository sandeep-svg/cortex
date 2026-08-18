require "test_helper"

class EmbeddingServiceTest < ActiveSupport::TestCase
  test "normalizes to unit length" do
    vector = EmbeddingService.normalize_and_pad([ 3.0, 4.0 ] + [ 0.0 ] * 50)
    assert_in_delta 1.0, Math.sqrt(vector.sum { |x| x * x }), 0.0001
  end

  test "pads to exactly VECTOR_DIM" do
    assert_equal EmbeddingService::VECTOR_DIM, EmbeddingService.normalize_and_pad([ 1.0, 2.0 ]).length
    assert_equal EmbeddingService::VECTOR_DIM, EmbeddingService.normalize_and_pad([ 1.0 ] * 3072).length
  end

  test "cosine similarity is preserved by normalization + padding" do
    a = [ 3.0, 4.0 ]
    b = [ 1.0, 0.0 ]

    raw_cosine = (a[0] * b[0] + a[1] * b[1]) / (Math.sqrt(a.sum { |x| x * x }) * Math.sqrt(b.sum { |x| x * x }))

    pa = EmbeddingService.normalize_and_pad(a)
    pb = EmbeddingService.normalize_and_pad(b)
    padded_cosine = pa.zip(pb).sum { |x, y| x * y } # both unit vectors -> dot product

    assert_in_delta raw_cosine, padded_cosine, 0.0001
  end

  test "raises with a clear message when no embedding provider exists" do
    Provider.update_all(embedding_model: nil)
    error = assert_raises(RuntimeError) { EmbeddingService.embed([ "hello" ]) }
    assert_match(/embedding model/i, error.message)
  end

  test "raises a clear message when the provider returns an empty vector" do
    provider = Provider.create!(name: "Ollama", slug: "ollama", enabled: true,
                                embedding_model: "missing-model", active: true)
    provider.define_singleton_method(:client) do
      Class.new do
        def embed_many(texts)
          [ nil ]
        end
      end.new
    end

    error = assert_raises(RuntimeError) { EmbeddingService.embed([ "hello" ], provider: provider) }
    assert_match(/empty vector/, error.message)
    assert_match(/missing-model/, error.message)
  end

  test "normalize_and_pad rejects nil vectors" do
    assert_raises(ArgumentError) { EmbeddingService.normalize_and_pad(nil) }
  end
end
