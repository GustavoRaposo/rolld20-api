class TurnEventProcessor
  EVENT_TO_MEMORY_TYPE = {
    "npc_met"             => "npc",
    "quest_started"       => "quest",
    "quest_completed"     => "quest",
    "location_discovered" => "location"
  }.freeze

  def initialize(turn:, character:, campaign:)
    @turn      = turn
    @character = character
    @campaign  = campaign
  end

  def call
    Array(@turn.game_events).each { |event| process(event) }
  end

  private

  def process(event)
    type = event["type"]

    case type
    when "xp_gain"
      grant_xp(event["amount"].to_i)
    when "npc_met", "quest_started", "quest_completed", "location_discovered", "item_found"
      create_memory(event, type)
    end
  end

  def grant_xp(amount)
    return if amount <= 0

    @character.with_lock do
      new_xp = @character.current_xp + amount
      attrs  = { current_xp: new_xp }

      if !@character.level_up_pending? && @character.level < 10
        next_xp = @character.xp_for_next_level
        attrs[:level_up_pending] = true if next_xp && new_xp >= next_xp
      end

      @character.update!(attrs)
    end
  end

  def create_memory(event, type)
    memory_type = EVENT_TO_MEMORY_TYPE[type] || "event"

    summary = case type
              when "npc_met"
                "Met NPC: #{event["name"]}. #{event["description"]}"
              when "quest_started"
                "Quest started: #{event["name"]}. #{event["description"]}"
              when "quest_completed"
                "Quest completed: #{event["name"]}"
              when "location_discovered"
                "Discovered location: #{event["name"]}. #{event["description"]}"
              when "item_found"
                "Found item: #{event["name"]}. #{event["description"]}"
              else
                event["description"].to_s
              end

    importance = event["importance"]&.to_i || default_importance(type)

    @campaign.campaign_memories.create!(
      memory_type:  memory_type,
      entity_name:  event["name"],
      summary:      summary,
      importance:   importance.clamp(1, 3),
      turn_number:  @turn.turn_number
    )
  end

  def default_importance(type)
    case type
    when "quest_started", "quest_completed" then 3
    when "npc_met", "location_discovered"   then 2
    else 1
    end
  end
end
