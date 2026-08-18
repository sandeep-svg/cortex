# Registry that maps a Provider slug to its HTTP/API adapter.
#
# Every adapter implements the same interface:
#   - chat(messages, stream:)  -> String (accumulated answer), yielding text fragments to `stream`
#   - embed(text)              -> Array<Float>
#   - embed_many(texts)        -> Array<Array<Float>> (optional, falls back to a loop)
#
# messages follow the OpenAI convention:
#   [{ role: "system", content: ... }, { role: "user", content: ... }]
module Llm
  REGISTRY = {}

  class << self
    def register(slug, klass)
      REGISTRY[slug.to_s] = klass
    end

    def build(provider)
      (REGISTRY[provider.slug.to_s] || Llm::OpenaiClient).new(provider)
    end

    def slugs
      REGISTRY.keys
    end
  end
end

Llm.register "openai",    Llm::OpenaiClient
Llm.register "anthropic", Llm::AnthropicClient
Llm.register "gemini",    Llm::GeminiClient
Llm.register "ollama",    Llm::OllamaClient
