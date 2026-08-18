module Llm
  class Base
    attr_reader :provider

    def initialize(provider)
      @provider = provider
    end

    def chat(messages, stream: nil)
      raise NotImplementedError, "#{self.class} must implement #chat"
    end

    def embed(text)
      raise NotImplementedError, "#{self.class} must implement #embed"
    end

    # Overridable: batched embeddings. Defaults to a loop.
    def embed_many(texts)
      texts.map { |text| embed(text) }
    end

    private

    # Ollama / Gemini return HTTP 200 with an error body (or non-2xx statuses)
    # instead of raising. Surface those as proper exceptions with the API's
    # own message so the UI can show something actionable. For streamed
    # requests the raw body is consumed by the fragment callback, so callers
    # pass it in via `body:`.
    def raise_http_error!(response, body: nil)
      return if response.success?

      error = response["error"]
      message =
        if error.is_a?(Hash)
          error["message"] || error.to_s
        elsif error.is_a?(String)
          error
        else
          response.body.to_s.first(300)
        end

      if message.blank? && body.present?
        parsed = JSON.parse(body) rescue nil
        message = parsed&.dig("error", "message") || parsed&.dig("message")
      end

      if message.blank?
        message =
          case response.code
          when 429 then "rate limit or quota exceeded — wait a moment and try again"
          when 404 then "HTTP 404 — the configured model may be retired or unavailable on this provider"
          else "HTTP #{response.code} — the provider returned an error without details"
          end
      end
      raise "API error (#{response.code}): #{message}"
    end

    # Splits incoming HTTP fragments into lines. A callback can be registered
    # so consumers yield SSE/JSONL deltas the moment a complete line arrives,
    # instead of waiting for the whole response.
    class LineBuffer
      attr_reader :lines, :raw

      def initialize(&on_line)
        @buffer = +""
        @lines = []
        @raw = +""
        @on_line = on_line
      end

      def <<(fragment)
        fragment = fragment.to_s
        @raw << fragment
        @buffer << fragment
        while (idx = @buffer.index("\n"))
          line = @buffer.slice!(0, idx + 1).strip
          next if line.empty?

          @lines << line
          @on_line&.call(line)
        end
      end

      def drain
        line = @buffer.strip
        @buffer = +""
        return if line.empty?

        @lines << line
        @on_line&.call(line)
      end
    end
  end
end
