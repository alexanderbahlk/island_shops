class Api::V1::ShopItemsController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    builder = ShopItemBuilder.new(shop_item_params, shop_item_update_params)
    
    if builder.build
      render json: { 
        shop_item: builder.shop_item, 
        shop_item_update: builder.shop_item_update 
      }, status: :created
    else
      render json: { errors: builder.errors }, status: :unprocessable_entity
    end
  end

  private
  
  def shop_item_params
    params.require(:shop_item).permit(:url, :title, :image_url, :size, :location, :product_id, :shop)
  end
  
  def shop_item_update_params
    params.require(:shop_item_update).permit(:price, :stock_status)
  end
end