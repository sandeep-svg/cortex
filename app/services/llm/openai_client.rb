module Llm
  class OpenaiClient < Base
    def client
      @client ||= OpenAI::Client.new(
        access_token: provider.api_key,
        uri_base: provider.base_url.presence || OpenAI::Configuration::DEFAULT_URI_BASE
      )
    end

    def chat(messages, stream: nil)
      params = {
        model: provider.chat_model,
        messages: messages,
        temperature: 0.3
      }

      if stream
        accumulator = +""
        params[:stream] = proc do |chunk, _bytesize|
          delta = chunk.dig("choices", 0, "delta", "content")
          next if delta.nil?

          accumulator << delta
          stream.call(delta)
        end
        client.chat(parameters: params)
        accumulator
      else
        client.chat(parameters: params).dig("choices", 0, "message", "content")
      end
    end

    def embed(text)
      response = client.embeddings(parameters: { model: provider.embedding_model, input: text })
      response.dig("data", 0, "embedding")
    end

    def embed_many(texts)
      texts.each_slice(16).flat_map do |batch|
        response = client.embeddings(parameters: { model: provider.embedding_model, input: batch })
        response["data"].sort_by { |d| d["index"] }.map { |d| d["embedding"] }
      end
    end
  end
end
