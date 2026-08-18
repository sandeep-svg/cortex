class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user

  private

  # A signed-in user (admin or regular).
  def current_user
    Current.user
  end

  # Regular users may only browse; everything else below is admin-only.
  def require_admin
    return if current_user&.admin?

    redirect_to root_path, alert: "You don't have permission to do that."
  end

  # Route admins to the dashboard, everyone else to the product page.
  def after_authentication_url
    return session.delete(:return_to_after_authenticating) if session[:return_to_after_authenticating]

    current_user.admin? ? dashboard_path : root_path
  end
end
