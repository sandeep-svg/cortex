module Llm
  class GeminiClient < Base
    BASE_URI = "https://generativelanguage.googleapis.com"

    def base_uri
      provider.base_url.presence || BASE_URI
    end

    def chat(messages, stream: nil)
      system = messages.find { |m| m[:role] == "system" }&.dig(:content)
      contents = messages.reject { |m| m[:role] == "system" }.map do |m|
        { role: m[:role] == "assistant" ? "model" : "user", parts: [ { text: m[:content] } ] }
      end

      url = "#{base_uri}/v1beta/models/#{provider.chat_model}:streamGenerateContent?alt=sse&key=#{provider.api_key}"
      body = {
        contents: contents,
        system_instruction: system && { parts: [ { text: system } ] }
      }.compact

      accumulator = +""
      on_line = lambda do |line|
        next unless line.start_with?("data:")

        json = line.delete_prefix("data:").strip
        next if json == "[DONE]"

        begin
          parsed = JSON.parse(json)
        rescue JSON::ParserError
          next
        end

        delta = parsed.dig("candidates", 0, "content", "parts", 0, "text")
        next if delta.nil? || delta.empty?

        accumulator << delta
        stream&.call(delta)
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
    end

    def embed(text)
      url = "#{base_uri}/v1beta/models/#{provider.embedding_model}:embedContent?key=#{provider.api_key}"
      response = HTTParty.post(
        url,
        body: { content: { parts: [ { text: text } ] } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      raise_http_error!(response)
      response.dig("embedding", "values")
    end
  end
end
