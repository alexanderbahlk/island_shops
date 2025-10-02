class Api::V1::ShopItemsController < Api::V1::SecureScrapeController
  def create_by_scrape
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

  def create
  end

  private

  def shop_item_params
    params.require(:shop_item).permit(:url, :title, :breadcrumb, :image_url, :size, :unit, :location, :product_id, :shop)
  end

  def shop_item_update_params
    params.require(:shop_item_update).permit(:price, :stock_status)
  end
end
