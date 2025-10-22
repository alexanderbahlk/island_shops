class Api::V1::ShopItemsController < Api::V1::SecureAppController
  def create
    # Request params look like this
    # final requestBody = {
    #  'shop_item': {
    #    'title': shopItemTitle,
    #    'size': shopItemSize,
    #    'unit': shopItemUnit,
    #  },
    #  'shop_item_update': {
    #    'price': shopItemPrice,
    #  },
    #  'place' : {
    #    'title': placeTitle,
    #    'location': placeLocation,
    #  },
    #  'add_to_active_shopping_list': addToActiveShoppingList,
    #
    #log params for debugging
    Rails.logger.debug("Received shop item params: #{params.inspect}")
    builder = AppShopItemBuilder.new(shop_item_params, shop_item_update_params, place_params, add_to_active_shopping_list_param)

    if builder.build
      render json: {
        shop_item: builder.shop_item,
        shop_item_update: builder.shop_item_update,
        place: builder.place,
      }, status: :created
    else
      render json: { errors: builder.errors }, status: :unprocessable_content
    end
  end

  private

  #permits params
  #adds current user to shop item params
  def shop_item_params
    params.require(:shop_item).permit(:title, :size, :unit).tap do |whitelisted|
      whitelisted[:user] = @current_user
    end
  end

  def shop_item_update_params
    params.require(:shop_item_update).permit(:price)
  end

  def place_params
    params.require(:place).permit(:title, :location)
  end

  def add_to_active_shopping_list_param
    params[:add_to_active_shopping_list] || false
  end
end
