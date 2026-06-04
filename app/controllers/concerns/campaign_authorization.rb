module CampaignAuthorization
  extend ActiveSupport::Concern

  included do
    helper_method :campaign_owner? if respond_to?(:helper_method)
  end

  private

  # Finds a campaign the current user can access (owner OR has a character in it).
  # Admins bypass the scope and can access any campaign.
  def set_accessible_campaign
    scope = current_user.admin? ? Campaign.all : Campaign.accessible_by(current_user)
    @campaign = scope.find_by!(slug: params[:campaign_id] || params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error "Campaign not found", status: :not_found
  end

  # Finds a campaign the current user owns.
  # Admins bypass the scope.
  def set_owned_campaign
    scope = current_user.admin? ? Campaign.all : Campaign.owned_by(current_user)
    @campaign = scope.find_by!(slug: params[:campaign_id] || params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error "Campaign not found", status: :not_found
  end

  # Raises 403 if the current user is not the campaign owner (and not admin).
  def require_owner!
    return if current_user.admin?
    return if campaign_owner?

    render_error "Forbidden", status: :forbidden
  end

  def campaign_owner?
    @campaign&.owner_id == current_user.id
  end
end
