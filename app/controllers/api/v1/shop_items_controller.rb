class Api::V1::ShopItemsController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    @shop_item = ShopItem.new(shop_item_params)
    
    if @shop_item.save
      render json: @shop_item, status: :created
    else
      render json: { errors: @shop_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private
  
  def shop_item_params
    params.require(:shop_item).permit(:url, :title, :image_url, :size, :location, :product_id)
  end
end
