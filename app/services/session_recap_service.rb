class SessionRecapService
  DEFAULT_TURNS_LIMIT = 20

  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are a scribe summarizing a tabletop RPG session for the players.
    Write an engaging, third-person narrative recap of the events described.
    Keep it concise (3-5 paragraphs), highlight key moments, decisions, and consequences.
    Respond with plain text only — no JSON, no markdown headers.
  PROMPT

  def initialize(campaign:, since_turn: nil, client: ClaudeClient.new)
    @campaign   = campaign
    @since_turn = since_turn&.to_i
    @client     = client
  end

  def call
    turns = fetch_turns
    return nil if turns.empty?

    @client.message(system: SYSTEM_PROMPT, user: build_user_message(turns))
  end

  private

  def fetch_turns
    scope = @campaign.turns.order(:turn_number)
    scope = scope.where("turn_number >= ?", @since_turn) if @since_turn
    scope.limit(DEFAULT_TURNS_LIMIT)
  end

  def build_user_message(turns)
    parts = ["Campaign: #{@campaign.name}", ""]

    turns.each do |t|
      parts << "Turn #{t.turn_number}"
      parts << "Player: #{t.player_action}"
      parts << "GM: #{t.gm_narrative}"
      parts << ""
    end

    parts.join("\n")
  end
end
