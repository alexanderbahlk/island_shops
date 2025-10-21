class Api::V1::ScrapedShopItemsController < ApplicationController
  SECURE_HASH = ENV.fetch("CATEGORIES_API_HASH", "gfh5haf_y6").freeze
  protect_from_forgery with: :null_session
  before_action :authenticate

  def create
    #log params for debugging
    Rails.logger.debug("Received shop item params: #{params.inspect}")
    builder = ScrapedShopItemBuilder.new(shop_item_params, shop_item_update_params)

    if builder.build
      render json: {
        shop_item: builder.shop_item,
        shop_item_update: builder.shop_item_update,
      }, status: :created
    else
      render json: { errors: builder.errors }, status: :unprocessable_content
    end
  end

  private

  def authenticate
    provided_hash = request.headers["X-SECURE-HASH"]
    #Rails.logger.info "Received X-SECURE-HASH: #{provided_hash}"
    #Rails.logger.info "Expected SECURE_HASH: #{SECURE_HASH}"
    unless ActiveSupport::SecurityUtils.secure_compare(provided_hash.to_s, SECURE_HASH)
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def shop_item_params
    params.require(:shop_item).permit(:url, :title, :breadcrumb, :image_url, :size, :unit, :place, :product_id, :shop)
  end

  def shop_item_update_params
    params.require(:shop_item_update).permit(:price, :stock_status)
  end
end
