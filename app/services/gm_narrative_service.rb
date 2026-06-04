class GmNarrativeService
  RECENT_TURNS_LIMIT    = 10
  RECENT_MEMORIES_LIMIT = 8
  LORE_CHUNKS_LIMIT     = 3

  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are the Game Master (GM) for a tabletop RPG campaign in a fantasy world.
    Your role is to narrate the story, describe the world, control NPCs, and resolve mechanics.

    Always respond with a valid JSON object and nothing else — no markdown, no code fences, just raw JSON:
    {
      "narrative": "<2-4 paragraphs of vivid, engaging narration>",
      "mechanic_result": {
        "roll": <integer 1-20 or null if no check needed>,
        "check": "<skill or stat name, e.g. perception, strength — or null>",
        "difficulty": <integer DC or null>,
        "success": <true/false or null>,
        "modifier": <integer or null>
      },
      "game_events": [
        // Zero or more of:
        // { "type": "xp_gain",            "amount": <10-100> }
        // { "type": "npc_met",            "name": "...", "description": "...", "importance": <1-3> }
        // { "type": "item_found",         "name": "...", "description": "..." }
        // { "type": "quest_started",      "name": "...", "description": "..." }
        // { "type": "quest_completed",    "name": "..." }
        // { "type": "location_discovered","name": "...", "description": "..." }
      ]
    }

    Rules:
    - Always award xp_gain when meaningful progress is made (exploration, combat, roleplay).
    - Keep the narrative consistent with prior events shown in the context.
    - If the action requires a dice check, fill mechanic_result accordingly; otherwise leave all fields null.
    - Respond ONLY with the JSON object.
  PROMPT

  Result = Struct.new(:narrative, :mechanic_result, :game_events, keyword_init: true)

  def initialize(campaign:, character:, player_action:, client: ClaudeClient.new, embedder: nil)
    @campaign      = campaign
    @character     = character
    @player_action = player_action
    @client        = client
    @embedder      = embedder
  end

  def call
    raw = @client.message(system: SYSTEM_PROMPT, user: build_user_message)
    parse(raw)
  end

  private

  def build_user_message
    parts = []

    parts << "## Campaign: #{@campaign.name}"
    parts << ""

    parts << "## Your Character"
    parts << "Name: #{@character.name}"
    parts << "Class: #{@character.character_class.capitalize}"
    parts << "Level: #{@character.level}"
    parts << "XP: #{@character.current_xp}"
    parts << ""

    recent = recent_turns
    if recent.any?
      parts << "## Recent History"
      recent.each do |t|
        parts << "Turn #{t.turn_number} — Player: #{t.player_action}"
        parts << "GM: #{t.gm_narrative}"
        parts << ""
      end
    end

    memories = relevant_memories
    if memories.any?
      parts << "## Important Events & Memories"
      memories.each { |m| parts << "- [#{m.memory_type.upcase}] #{m.summary}" }
      parts << ""
    end

    lore = relevant_lore
    if lore.any?
      parts << "## World Lore (relevant excerpts)"
      lore.each { |chunk| parts << chunk.content }
      parts << ""
    end

    parts << "## Player Action"
    parts << @player_action

    parts.join("\n")
  end

  def recent_turns
    @campaign.turns
             .order(turn_number: :desc)
             .limit(RECENT_TURNS_LIMIT)
             .to_a
             .reverse
  end

  def relevant_memories
    @campaign.campaign_memories
             .order(importance: :desc, created_at: :desc)
             .limit(RECENT_MEMORIES_LIMIT)
  end

  def relevant_lore
    return [] unless @campaign.world_configured?

    embedder = @embedder || EmbeddingClient.new
    query_vector = embedder.embed(@player_action)
    @campaign.world_lore_embeddings
             .nearest_neighbors(:embedding, query_vector, distance: "cosine")
             .limit(LORE_CHUNKS_LIMIT)
  rescue EmbeddingClient::ApiError
    []
  end

  def parse(raw)
    data = JSON.parse(raw)
    Result.new(
      narrative:       data["narrative"].to_s,
      mechanic_result: data["mechanic_result"],
      game_events:     Array(data["game_events"])
    )
  rescue JSON::ParserError => e
    raise ClaudeClient::ApiError, "Invalid JSON from GM: #{e.message}"
  end
end
