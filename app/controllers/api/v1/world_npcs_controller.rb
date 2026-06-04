class Api::V1::WorldNpcsController < ApplicationController
  include CampaignAuthorization

  before_action :set_accessible_campaign, only: [:index]
  before_action :set_owned_campaign,      only: [:create]

  def index
    npcs = @campaign.campaign_memories.by_type("npc").order(importance: :desc, created_at: :desc)
    render json: npcs.map { |m| npc_json(m) }
  end

  def create
    memory = @campaign.campaign_memories.build(npc_params.merge(memory_type: "npc"))
    if memory.save
      render json: npc_json(memory), status: :created
    else
      render_error memory.errors.full_messages.join(", ")
    end
  end

  private

  def npc_params
    params.require(:npc).permit(:entity_name, :summary, :importance, :aspect)
  end

  def npc_json(memory)
    {
      id:          memory.id,
      name:        memory.entity_name,
      summary:     memory.summary,
      aspect:      memory.aspect,
      importance:  memory.importance,
      turn_number: memory.turn_number,
      created_at:  memory.created_at
    }
  end
end
