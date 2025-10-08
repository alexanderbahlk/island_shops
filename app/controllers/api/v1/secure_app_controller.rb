class Api::V1::SecureAppController < ApplicationController
  protect_from_forgery with: :null_session
  before_action :authenticate

  attr_reader :current_user

  private

  def authenticate
    provided_app_user_hash = request.headers["X-SECURE-APP-USER-HASH"]
    Rails.logger.info "Received X-SECURE-APP-USER-HASH: #{provided_app_user_hash}"
    if provided_app_user_hash.blank?
      return render json: { error: "Invalid APP-USER-HASH" }, status: :bad_request
    end

    @current_user = User.find_by(app_hash: provided_app_user_hash)
    if @current_user.nil?
      return render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
