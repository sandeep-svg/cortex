module Llm
  class OllamaClient < Base
    BASE_URI = "http://localhost:11434"

    def base_uri
      provider.base_url.presence || BASE_URI
    end

    def chat(messages, stream: nil)
      url = "#{base_uri}/api/chat"
      body = {
        model: provider.chat_model,
        messages: messages,
        stream: !stream.nil?,
        options: { temperature: 0.3 }
      }

      if stream
        accumulator = +""
        on_line = lambda do |line|
          begin
            parsed = JSON.parse(line)
          rescue JSON::ParserError
            next
          end
          delta = parsed.dig("message", "content")
          next if delta.nil? || delta.empty?

          accumulator << delta
          stream.call(delta)
        end

        buffer = LineBuffer.new(&on_line)
        response = HTTParty.post(
          url,
          body: body.to_json,
          headers: { "Content-Type" => "application/json" },
          stream_body: true
        ) { |fragment| buffer << fragment }
        raise_http_error!(response, body: buffer.raw)
        buffer.drain

        accumulator
      else
        response = HTTParty.post(url, body: body.to_json, headers: { "Content-Type" => "application/json" })
        raise_http_error!(response)
        response.dig("message", "content")
      end
    end

    def embed(text)
      url = "#{base_uri}/api/embed"
      response = HTTParty.post(url, body: { model: provider.embedding_model, input: text }.to_json,
                                    headers: { "Content-Type" => "application/json" })
      raise_http_error!(response)
      response.dig("embeddings", 0)
    end

    def embed_many(texts)
      url = "#{base_uri}/api/embed"
      response = HTTParty.post(url, body: { model: provider.embedding_model, input: texts }.to_json,
                                    headers: { "Content-Type" => "application/json" })
      raise_http_error!(response)
      response["embeddings"]
    end
  end
end
