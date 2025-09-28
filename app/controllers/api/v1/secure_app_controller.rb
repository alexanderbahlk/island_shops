class Api::V1::SecureAppController < ApplicationController
  SECURE_HASH = ENV.fetch("CATEGORIES_API_HASH", "gfh5haf_y6").freeze
  protect_from_forgery with: :null_session
  before_action :authenticate

  attr_reader :current_user

  private

  def authenticate
    provided_hash = request.headers["X-SECURE-HASH"]
    Rails.logger.info "Received X-SECURE-HASH: #{provided_hash}"
    Rails.logger.info "Expected SECURE_HASH: #{SECURE_HASH}"

    unless ActiveSupport::SecurityUtils.secure_compare(provided_hash.to_s, SECURE_HASH)
      render json: { error: "Unauthorized" }, status: :unauthorized
    end

    provided_app_user_hash = request.headers["X-SECURE-APP-USER-HASH"]
    Rails.logger.info "Received X-SECURE-APP-USER-HASH: #{provided_app_user_hash}"
    if !provided_app_user_hash.blank?
      @current_user = User.find_by(app_hash: provided_app_user_hash)
      #just create a new user
      if @current_user.nil?
        @current_user = User.create!(app_hash: provided_app_user_hash)
      end
    end
  end
end
