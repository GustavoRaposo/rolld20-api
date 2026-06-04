class Api::V1::WorldsController < ApplicationController
  include CampaignAuthorization

  before_action :set_accessible_campaign, only: [:show]
  before_action :set_owned_campaign,      only: [:create]

  def show
    render json: world_json
  end

  def create
    lore = params.require(:world).permit(:lore)[:lore]
    return render_error "lore is required" if lore.blank?

    result = WorldLoreIngestor.new(campaign: @campaign).call(lore)
    render json: world_json.merge(chunks_added: result[:added], chunks_total: result[:total]), status: :created

  rescue EmbeddingClient::ApiError => e
    render_error "Embedding service error: #{e.message}", status: :service_unavailable
  end

  private

  def world_json
    {
      campaign_id:      @campaign.id,
      world_configured: @campaign.world_configured,
      lore_chunks:      @campaign.world_lore_embeddings.count
    }
  end
end
