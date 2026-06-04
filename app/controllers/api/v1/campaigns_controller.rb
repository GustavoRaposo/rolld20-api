class Api::V1::CampaignsController < ApplicationController
  include CampaignAuthorization

  before_action :set_accessible_campaign, only: [:show, :recap]
  before_action :set_owned_campaign,      only: [:start, :archive]

  def index
    scope = current_user.admin? ? Campaign.all : Campaign.accessible_by(current_user)
    campaigns = scope.order(created_at: :desc)
    render json: campaigns.map { |c| campaign_json(c) }
  end

  def create
    campaign = current_user.campaigns.build(campaign_params)
    if campaign.save
      render json: campaign_json(campaign), status: :created
    else
      render_error campaign.errors.full_messages.join(", ")
    end
  end

  def show
    render json: campaign_json(@campaign, include_characters: true)
  end

  def start
    if @campaign.setup?
      @campaign.update!(status: "active", started_at: Time.current)
      render json: campaign_json(@campaign)
    else
      render_error "Campaign is already #{@campaign.status}", status: :unprocessable_entity
    end
  end

  def archive
    if @campaign.archived?
      render_error "Campaign is already archived", status: :unprocessable_entity
    else
      @campaign.archived!
      render json: campaign_json(@campaign)
    end
  end

  def recap
    recap_text = SessionRecapService.new(
      campaign:   @campaign,
      since_turn: params[:since_turn]
    ).call

    if recap_text
      render json: { campaign_id: @campaign.id, recap: recap_text }
    else
      render_error "No turns found to recap", status: :unprocessable_entity
    end
  rescue ClaudeClient::ApiError => e
    render_error "Recap service error: #{e.message}", status: :service_unavailable
  end

  private

  def campaign_params
    params.require(:campaign).permit(:name)
  end

  def campaign_json(campaign, include_characters: false)
    json = {
      id:               campaign.id,
      name:             campaign.name,
      slug:             campaign.slug,
      status:           campaign.status,
      world_configured: campaign.world_configured,
      is_owner:         campaign.owner_id == current_user.id,
      started_at:       campaign.started_at,
      created_at:       campaign.created_at
    }
    if include_characters
      json[:characters] = campaign.characters.map { |ch| character_summary(ch) }
    end
    json
  end

  def character_summary(character)
    {
      id:               character.id,
      name:             character.name,
      character_class:  character.character_class,
      level:            character.level,
      current_xp:       character.current_xp,
      level_up_pending: character.level_up_pending
    }
  end
end
