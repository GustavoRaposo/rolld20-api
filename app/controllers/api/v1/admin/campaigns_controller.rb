class Api::V1::Admin::CampaignsController < ApplicationController
  include AdminAuthorization

  def index
    campaigns = Campaign.includes(:owner, :characters).order(created_at: :desc)
    render json: campaigns.map { |c| campaign_json(c) }
  end

  def destroy
    campaign = Campaign.find(params[:id])
    campaign.destroy!
    head :no_content
  rescue ActiveRecord::RecordNotFound
    render_error "Campaign not found", status: :not_found
  end

  private

  def campaign_json(campaign)
    {
      id:               campaign.id,
      name:             campaign.name,
      slug:             campaign.slug,
      status:           campaign.status,
      world_configured: campaign.world_configured,
      characters_count: campaign.characters.size,
      owner: {
        id:    campaign.owner.id,
        email: campaign.owner.email
      },
      started_at: campaign.started_at,
      created_at: campaign.created_at
    }
  end
end
