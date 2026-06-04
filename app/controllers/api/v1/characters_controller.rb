class Api::V1::CharactersController < ApplicationController
  before_action :set_join_campaign, only: [:create]
  before_action :set_character,     only: [:show, :level_up, :roll_attributes]

  def create
    unless @campaign.setup?
      return render_error "Cannot join a campaign that is already #{@campaign.status}", status: :unprocessable_entity
    end

    character = @campaign.characters.build(character_params.merge(user: current_user))
    if character.save
      render json: character_json(character), status: :created
    else
      render_error character.errors.full_messages.join(", ")
    end
  end

  def show
    render json: character_json(@character)
  end

  def level_up
    if request.get?
      render json: level_up_status(@character)
    else
      perform_level_up
    end
  end

  def roll_attributes
    attributes = %i[strength dexterity constitution intelligence wisdom charisma]
    rolled = attributes.index_with { roll_4d6_drop_lowest }
    render json: { attributes: rolled }
  end

  private

  # Any authenticated user can join any campaign (self-join), restricted to setup status.
  def set_join_campaign
    @campaign = Campaign.find_by!(slug: params[:campaign_id])
  rescue ActiveRecord::RecordNotFound
    render_error "Campaign not found", status: :not_found
  end

  def set_character
    @character = current_user.characters.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error "Character not found", status: :not_found
  end

  def character_params
    params.require(:character).permit(:name, :character_class)
  end

  def perform_level_up
    unless @character.level_up_pending?
      return render_error "No level up pending", status: :unprocessable_entity
    end

    if @character.update(level: @character.level + 1, level_up_pending: false)
      render json: character_json(@character)
    else
      render_error @character.errors.full_messages.join(", ")
    end
  end

  def level_up_status(character)
    {
      level_up_pending:  character.level_up_pending,
      level:             character.level,
      current_xp:        character.current_xp,
      xp_for_next_level: character.xp_for_next_level
    }
  end

  def character_json(character)
    {
      id:                character.id,
      name:              character.name,
      character_class:   character.character_class,
      level:             character.level,
      current_xp:        character.current_xp,
      xp_for_next_level: character.xp_for_next_level,
      level_up_pending:  character.level_up_pending,
      campaign_id:       character.campaign_id,
      created_at:        character.created_at
    }
  end

  def roll_4d6_drop_lowest
    rolls = Array.new(4) { rand(1..6) }
    rolls.sum - rolls.min
  end
end
