class ClaudeClient
  API_URL   = "https://api.anthropic.com/v1/messages".freeze
  MODEL     = "claude-sonnet-4-6".freeze
  MAX_TOKENS = 2048

  class ApiError < StandardError; end

  def initialize
    @api_key = ENV.fetch("ANTHROPIC_API_KEY")
    @conn = Faraday.new do |f|
      f.request  :json
      f.response :json
      f.adapter  Faraday.default_adapter
    end
  end

  # Returns the assistant text content as a String.
  # Raises ApiError on non-2xx responses.
  def message(system:, user:, max_tokens: MAX_TOKENS)
    response = @conn.post(API_URL) do |req|
      req.headers["x-api-key"]         = @api_key
      req.headers["anthropic-version"] = "2023-06-01"
      req.body = {
        model:      MODEL,
        max_tokens: max_tokens,
        system:     system,
        messages:   [{ role: "user", content: user }]
      }
    end

    unless response.success?
      raise ApiError, "Claude API error #{response.status}: #{response.body}"
    end

    response.body.dig("content", 0, "text")
  end
end
