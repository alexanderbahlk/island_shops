class SecureAppController < ApplicationController
  SECURE_HASH = ENV.fetch("CATEGORIES_API_HASH", "gfh5haf_y6").freeze
  protect_from_forgery with: :null_session
  before_action :authenticate

  private

  def authenticate
    provided_hash = request.headers["X-SECURE-HASH"]
    unless ActiveSupport::SecurityUtils.secure_compare(provided_hash.to_s, SECURE_HASH)
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
