require "test_helper"

class LlmBaseTest < ActiveSupport::TestCase
  class FakeResponse
    def initialize(code, body = nil)
      @code = code
      @body = body
    end

    def success?
      @code < 300
    end

    def code
      @code
    end

    def body
      @body
    end

    def [](_key)
      nil
    end
  end

  test "429 with empty body gets a rate-limit hint" do
    error = assert_raises(RuntimeError) do
      Llm::Base.new(Provider.new).send(:raise_http_error!, FakeResponse.new(429))
    end
    assert_includes error.message, "rate limit or quota exceeded"
  end

  test "streamed 429 surfaces the API's own message from the raw body" do
    body = { error: { code: 429, message: "RESOURCE_EXHAUSTED: Quota exceeded" } }.to_json
    error = assert_raises(RuntimeError) do
      Llm::Base.new(Provider.new).send(:raise_http_error!, FakeResponse.new(429, nil), body: body)
    end
    assert_includes error.message, "RESOURCE_EXHAUSTED: Quota exceeded"
  end

  test "404 with empty body gets a model-retired hint" do
    error = assert_raises(RuntimeError) do
      Llm::Base.new(Provider.new).send(:raise_http_error!, FakeResponse.new(404))
    end
    assert_includes error.message, "model may be retired"
  end

  test "successful responses never raise" do
    assert_nil Llm::Base.new(Provider.new).send(:raise_http_error!, FakeResponse.new(200))
  end
end
