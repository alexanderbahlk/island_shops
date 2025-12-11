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
    # log params for debugging
    Rails.logger.debug("Received shop item params: #{params.inspect}")
    builder = AppShopItemBuilder.new(shop_item_params, shop_item_update_params, place_params,
                                     add_to_active_shopping_list_param)

    if builder.build
      render json: {
        shop_item: builder.shop_item,
        shop_item_update: builder.shop_item_update,
        place: builder.place
      }, status: :created
    else
      render json: { errors: builder.errors }, status: :unprocessable_content
    end
  end

  def lookup # by title
    Rails.logger.debug("Received shop item params: #{params.inspect}")
    title_query = params[:title]
    # sanatize input
    clean_title_query = title_query.to_s.strip

    render json: { error: 'Title parameter is required' }, status: :bad_request and return if clean_title_query.blank?

    matcher = ShopItemMatchers::ShopItemMatcher.new(title: clean_title_query, sim: 0.1)
    matching_shop_items = matcher.find_best_match

    if matching_shop_items.nil?
      render json: { error: 'No matching shop items found' }, status: :not_found
    elsif Rails.logger.debug("Lookup for title '#{clean_title_query}' found #{matching_shop_items.size} items.")
      render json: matching_shop_items, status: :ok
    end
  end

  private

  # permits params
  # adds current user to shop item params
  def shop_item_params
    params.require(:shop_item).permit(:title, :size, :unit).tap do |whitelisted|
      whitelisted[:user] = @current_user
    end
  end

  def shop_item_update_params
    params.require(:shop_item_update).permit(:price)
  end

  def place_params
    params.require(:place).permit(:title, :location, :latitude, :longitude)
  end

  def add_to_active_shopping_list_param
    params[:add_to_active_shopping_list] || false
  end
end
