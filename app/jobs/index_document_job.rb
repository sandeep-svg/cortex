# The document ingestion pipeline:
#   extract text -> chunk -> embed -> store chunks (with vectors) in PostgreSQL
#
# Runs as a background job so uploads feel instant; the UI polls document status.
class IndexDocumentJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(document)
    document.update!(status: "processing")

    text = DocumentExtractor.extract(document)
    chunks = Chunker.call(text)

    vectors = EmbeddingService.embed(chunks)
    raise "Embedding provider returned #{vectors.length} vectors for #{chunks.length} chunks" if vectors.length != chunks.length

    document.transaction do
      document.chunks.delete_all
      chunks.each_with_index do |content, index|
        document.chunks.create!(
          content: content,
          position: index,
          token_count: Chunker.token_count(content),
          embedding: vectors[index]
        )
      end
      document.update!(
        status: "completed",
        chunk_count: chunks.length,
        word_count: text.split.size,
        processed_at: Time.current
      )
    end
  rescue StandardError => e
    document.update!(status: "failed", error: e.message)
    raise
  end
end
