class FindCategoryForShopItemService
  attr_reader :shop_item

  def initialize(shop_item:)
    @shop_item = shop_item
  end

  def find
    best_match = CategoryFinderMatchers::ShopItemShopItemMatcher.new(shop_item: shop_item, sim: 0.15).find_best_match

    if best_match.nil?
      # Use the category matcher to find the best match
      best_match = CategoryFinderMatchers::ShopItemCategoryMatcher.new(shop_item: shop_item, sim: 0.22).find_best_match
    end
    best_match
  end
end
