class Api::V1::SecureScrapeController < ApplicationController
  SECURE_HASH = ENV.fetch("CATEGORIES_API_HASH", "gfh5haf_y6").freeze
  protect_from_forgery with: :null_session
  before_action :authenticate

  attr_reader :current_user

  private

  def authenticate
    provided_hash = request.headers["X-SECURE-HASH"]
    #Rails.logger.info "Received X-SECURE-HASH: #{provided_hash}"
    #Rails.logger.info "Expected SECURE_HASH: #{SECURE_HASH}"
    unless ActiveSupport::SecurityUtils.secure_compare(provided_hash.to_s, SECURE_HASH)
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
