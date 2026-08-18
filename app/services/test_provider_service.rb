# Verifies a provider's credentials and models by making two tiny real API calls:
#   - one embedding (skipped if the provider has no embedding model)
#   - one chat ping ("Say OK")
class TestProviderService
  class << self
    def call(provider)
      client = provider.client
      details = []

      if provider.embedding_model?
        embedding = client.embed("ping")
        raise "Embedding API returned no vector" if embedding.blank?
        details << "embedding #{embedding.length}d OK"
      end

      if provider.chat_model?
        answer = client.chat([ { role: "user", content: "Reply with exactly: OK" } ])
        raise "Chat API returned no answer" if answer.blank?
        details << "chat OK (#{answer.strip.first(40)})"
      end

      { ok: true, details: details.join(" · ") }
    rescue StandardError => e
      { ok: false, error: e.message }
    end
  end
end
