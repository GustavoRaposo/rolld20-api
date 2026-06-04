class Api::V1::CampaignMemoriesController < ApplicationController
  include CampaignAuthorization

  before_action :set_accessible_campaign
  before_action :set_memory, only: [:update, :destroy]
  before_action :require_owner!, only: [:update, :destroy]

  PAGE_SIZE = 50

  def index
    page     = [params.fetch(:page, 1).to_i, 1].max
    memories = @campaign.campaign_memories
                        .order(importance: :desc, created_at: :desc)

    memories = memories.by_type(params[:type]) if params[:type].present?
    memories = memories.offset((page - 1) * PAGE_SIZE).limit(PAGE_SIZE)

    render json: {
      page:     page,
      memories: memories.map { |m| memory_json(m) }
    }
  end

  def update
    if @memory.update(memory_params)
      render json: memory_json(@memory)
    else
      render_error @memory.errors.full_messages.join(", ")
    end
  end

  def destroy
    @memory.destroy!
    head :no_content
  end

  private

  def set_memory
    @memory = @campaign.campaign_memories.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error "Memory not found", status: :not_found
  end

  def memory_params
    params.require(:memory).permit(:summary, :importance, :aspect, :entity_name)
  end

  def memory_json(memory)
    {
      id:          memory.id,
      memory_type: memory.memory_type,
      entity_name: memory.entity_name,
      aspect:      memory.aspect,
      summary:     memory.summary,
      importance:  memory.importance,
      turn_number: memory.turn_number,
      created_at:  memory.created_at
    }
  end
end
