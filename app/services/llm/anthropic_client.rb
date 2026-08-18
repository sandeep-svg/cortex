module Llm
  class AnthropicClient < Base
    def client
      @client ||= Anthropic::Client.new(access_token: provider.api_key)
    end

    def chat(messages, stream: nil)
      system = messages.find { |m| m[:role] == "system" }&.dig(:content)
      conversation = messages.reject { |m| m[:role] == "system" }.map do |m|
        { role: m[:role] == "assistant" ? "assistant" : "user", content: m[:content] }
      end

      params = {
        model: provider.chat_model,
        max_tokens: 2048,
        temperature: 0.3,
        system: system,
        messages: conversation
      }

      if stream
        accumulator = +""
        params[:stream] = proc do |chunk|
          delta = chunk.is_a?(Hash) ? (chunk["delta"] || chunk[:delta]) : nil
          text = delta.is_a?(Hash) ? (delta["text"] || delta[:text]) : nil
          next if text.nil?

          accumulator << text
          stream.call(text)
        end
        client.messages(parameters: params)
        accumulator
      else
        response = client.messages(parameters: params)
        response.dig("content", 0, "text")
      end
    end

    # Anthropic's official API has no embedding endpoint yet —
    # the admin should point embeddings at another provider (e.g. OpenAI or Ollama).
    def embed(text)
      raise NotImplementedError, "Anthropic does not provide an embeddings API; use another provider for embeddings"
    end
  end
end
