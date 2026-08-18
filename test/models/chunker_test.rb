require "test_helper"

class ChunkerTest < ActiveSupport::TestCase
  test "splits long text into chunks of at most CHUNK_SIZE" do
    text = ("The quick brown fox jumps over the lazy dog. " * 100)
    chunks = Chunker.call(text)

    assert_operator chunks.length, :>, 1
    chunks.each { |c| assert_operator c.length, :<=, Chunker::CHUNK_SIZE }
  end

  test "chunks overlap by OVERLAP characters" do
    text = "Sentence one ends here. " * 200
    chunks = Chunker.call(text)

    chunks.each_cons(2) do |a, b|
      overlap = a.last(Chunker::OVERLAP)
      assert b.start_with?(overlap), "expected overlap context between consecutive chunks"
    end
  end

  test "prefers sentence boundaries over hard cuts" do
    text = ("a" * 500) + ". " + ("b" * 2000)
    chunks = Chunker.call(text)

    assert_operator chunks.first.length, :<=, 501
    assert_operator chunks.first.length, :>, 400
  end

  test "handles empty and whitespace-only input" do
    assert_empty Chunker.call("")
    assert_empty Chunker.call("   \n\t  ")
  end

  test "token count is roughly chars/4" do
    assert_equal 25, Chunker.token_count("a" * 100)
  end
end
