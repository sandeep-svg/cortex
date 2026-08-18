# The RAG (Retrieval-Augmented Generation) pipeline:
#
#   1. Embed the user's question        (EmbeddingService)
#   2. Find the nearest chunks          (pgvector cosine search)
#   3. Build a prompt with that context (retrieved chunks)
#   4. Stream the LLM's answer          (active provider's chat model)
#
# Events yielded to the block (for SSE streaming):
#   { type: :sources, payload: [...top chunks...] }
#   { type: :delta,   payload: "text fragment" }
#   { type: :done,    payload: { query_id: ... } }
#   { type: :error,   payload: "message" }
class RagService
  TOP_K = 6

  SYSTEM_PROMPT = <<~PROMPT.strip
    You are Cortex, a precise retrieval-augmented assistant. You answer questions
    using ONLY the context passages below, which were retrieved from the user's
    own documents.

    Rules:
    - Base every claim on the provided context. Never invent facts.
    - If the context does not contain the answer, say so plainly instead of guessing.
    - Quote the document when it is useful, and reference sources like [Source 1].
    - Keep answers clear and well-structured. Use markdown when it helps readability.
  PROMPT

  class << self
    def generate(query, document: nil, &block)
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      provider = Provider.active_chat_provider
      raise "No active chat provider configured. Go to the admin panel and activate one." unless provider

      embedder = EmbeddingService.embedder
      raise "No provider with an embedding model is enabled. Configure one in the admin panel." unless embedder

      # 1 + 2. Embed the question and find nearest chunks (optionally scoped to one document)
      question_vector = EmbeddingService.query_vector(query.question, provider: embedder)
      chunks = Chunk.nearest(question_vector, limit: TOP_K)
      chunks = chunks.where(document_id: document.id) if document

      results = chunks.map { |chunk| [ chunk, chunk.neighbor_distance ] }
      yield({ type: :sources, payload: results.map { |chunk, distance| source_payload(chunk, distance) } })

      # 3. Build the prompt: retrieved context + the question
      context = results.each_with_index.map do |(chunk, distance), index|
        "[Source #{index + 1}] (from \"#{chunk.document.title}\", relevance #{format('%.1f', (1 - distance) * 100)}%)\n#{chunk.content}"
      end.join("\n\n---\n\n")

      prompt = <<~TEXT
        #{SYSTEM_PROMPT}

        === RETRIEVED CONTEXT ===
        #{context}
        === END CONTEXT ===

        User question: #{query.question}
      TEXT

      # 4. Stream the answer from the active provider
      answer = provider.client.chat(
        [ { role: "system", content: prompt }, { role: "user", content: query.question } ],
        stream: ->(delta) { yield({ type: :delta, payload: delta }) }
      )

      query.update!(
        provider_id: provider.id,
        model: provider.chat_model,
        answer: answer,
        status: "completed",
        sources: results.map { |chunk, distance| source_payload(chunk, distance) },
        latency_ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
      )

      yield({ type: :done, payload: { query_id: query.id } })
      query
    rescue StandardError => e
      query.update!(status: "failed", answer: e.message)
      yield({ type: :error, payload: e.message })
      raise
    end

    private

    def source_payload(chunk, distance)
      {
        chunk_id: chunk.id,
        document_id: chunk.document_id,
        document_title: chunk.document&.title,
        position: chunk.position,
        relevance: (1 - distance).round(4),
        snippet: chunk.content.truncate(220)
      }
    end
  end
end
