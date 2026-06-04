class EmbeddingClient
  API_URL = "https://api.openai.com/v1/embeddings".freeze
  MODEL   = "text-embedding-ada-002".freeze

  class ApiError < StandardError; end

  def initialize
    @api_key = ENV.fetch("OPENAI_API_KEY")
    @conn = Faraday.new do |f|
      f.request  :json
      f.response :json
      f.adapter  Faraday.default_adapter
    end
  end

  # Returns a Float array of 1536 dimensions.
  def embed(text)
    response = @conn.post(API_URL) do |req|
      req.headers["Authorization"] = "Bearer #{@api_key}"
      req.body = { model: MODEL, input: text.strip }
    end

    unless response.success?
      raise ApiError, "OpenAI embeddings error #{response.status}: #{response.body}"
    end

    response.body.dig("data", 0, "embedding")
  end
end
