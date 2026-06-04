class Api::V1::TurnsController < ApplicationController
  include CampaignAuthorization

  before_action :set_accessible_campaign

  PAGE_SIZE = 50

  def index
    page  = [params.fetch(:page, 1).to_i, 1].max
    turns = @campaign.turns.order(:turn_number).offset((page - 1) * PAGE_SIZE).limit(PAGE_SIZE)
    render json: {
      page:  page,
      turns: turns.map { |t| turn_json(t) }
    }
  end

  def create
    unless @campaign.active?
      return render_error "Campaign is not active", status: :unprocessable_entity
    end

    character = @campaign.characters.find_by(user: current_user)
    unless character
      return render_error "You don't have a character in this campaign", status: :unprocessable_entity
    end

    player_action = params.require(:turn).permit(:player_action)[:player_action]
    if player_action.blank?
      return render_error "player_action is required"
    end

    result = GmNarrativeService.new(
      campaign:      @campaign,
      character:     character,
      player_action: player_action
    ).call

    turn = @campaign.with_lock do
      @campaign.turns.create!(
        character:       character,
        turn_number:     Turn.next_number_for(@campaign.id),
        player_action:   player_action,
        gm_narrative:    result.narrative,
        mechanic_result: result.mechanic_result,
        game_events:     result.game_events
      )
    end

    TurnEventProcessor.new(
      turn:      turn,
      character: character,
      campaign:  @campaign
    ).call

    render json: turn_json(turn), status: :created

  rescue ClaudeClient::ApiError => e
    render_error "GM service error: #{e.message}", status: :service_unavailable
  end

  private

  def turn_json(turn)
    {
      id:              turn.id,
      turn_number:     turn.turn_number,
      player_action:   turn.player_action,
      gm_narrative:    turn.gm_narrative,
      mechanic_result: turn.mechanic_result,
      game_events:     turn.game_events,
      character_id:    turn.character_id,
      created_at:      turn.created_at
    }
  end
end
