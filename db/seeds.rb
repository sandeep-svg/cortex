# Seed the four built-in LLM providers. API keys are intentionally left blank —
# add them from the admin panel (or via env vars below).
providers = [
  {
    slug: "openai", name: "OpenAI", api_key: ENV["OPENAI_API_KEY"].to_s,
    chat_model: "gpt-4o-mini", embedding_model: "text-embedding-3-small",
    embedding_dimensions: 1536,
    notes: "Chat + embeddings. text-embedding-3-small gives 1536 dims, text-embedding-3-large gives 3072."
  },
  {
    slug: "anthropic", name: "Anthropic", api_key: ENV["ANTHROPIC_API_KEY"].to_s,
    chat_model: "claude-sonnet-4-20250514", embedding_model: nil,
    embedding_dimensions: nil,
    notes: "Great chat quality. No embedding API — point embeddings at OpenAI, Gemini or Ollama."
  },
  {
    slug: "gemini", name: "Google Gemini", api_key: ENV["GEMINI_API_KEY"].to_s,
    chat_model: "gemini-3.5-flash-lite", embedding_model: "gemini-embedding-001",
    embedding_dimensions: 3072,
    notes: "Free tier available. Flash-Lite is the fastest/cheapest chat model; gemini-embedding-001 outputs 3072 dims."
  },
  {
    slug: "ollama", name: "Ollama (local)", api_key: "",
    chat_model: "llama3.2", embedding_model: "nomic-embed-text",
    embedding_dimensions: 768,
    notes: "100% local and free. brew install ollama, then: ollama pull llama3.2 && ollama pull nomic-embed-text"
  }
]

providers.each do |attrs|
  Provider.find_or_create_by!(slug: attrs[:slug]) do |p|
    p.name = attrs[:name]
    p.api_key = attrs[:api_key]
    p.chat_model = attrs[:chat_model]
    p.embedding_model = attrs[:embedding_model]
    p.embedding_dimensions = attrs[:embedding_dimensions]
    p.notes = attrs[:notes]
  end
end

puts "Seeded #{Provider.count} providers: #{Provider.pluck(:slug).join(', ')}"
puts "Next: set API keys and activate a provider at /admin/providers"

# Demo accounts so you can explore both roles immediately.
demo_users = [
  { email_address: "admin@cortex.dev", password: "password123", role: "admin" },
  { email_address: "user@cortex.dev", password: "password123", role: "user" }
]

demo_users.each do |attrs|
  User.find_or_create_by!(email_address: attrs[:email_address]) do |u|
    u.password = attrs[:password]
    u.role = attrs[:role]
  end
end

puts "Seeded #{User.count} users (admin@cortex.dev / password123, user@cortex.dev / password123)"
