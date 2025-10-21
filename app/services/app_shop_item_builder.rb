class AppShopItemBuilder
  attr_reader :shop_item, :shop_item_update, :place, :errors

  def initialize(shop_item_params, shop_item_update_params, place_params)
    @shop_item_params = shop_item_params
    @shop_item_update_params = shop_item_update_params
    @place_params = place_params
    @errors = []
  end

  def build
    success?
  end

  def success?
    @errors.empty?
  end

  private
end
