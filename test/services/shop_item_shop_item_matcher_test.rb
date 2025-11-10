require "test_helper"

class ShopItemShopItemMatcherTest < ActiveSupport::TestCase
  include TitleNormalizer

  def setup
    @place = places(:place_one)
  end

  test "should match organic milk category" do
    approvedOrganicMilkShopItem = shop_items(:shop_item_one)
    newOrganicMilkShopItem = ShopItem.new(title: "Organic Milk 1l", url: "www.example.com", breadcrumb: "PriceSmart > Groceries > Dairy and Eggs", place: @place)
    result = ShopItemShopItemMatcher.new(shop_item: newOrganicMilkShopItem).find_best_match

    assert_equal approvedOrganicMilkShopItem.category, result
  end

  test "should not match gouda cheese category" do
    newGoatCheeseShopItem = ShopItem.new(title: "Gouda Cheese", url: "www.example.com", place: @place)
    result = ShopItemShopItemMatcher.new(shop_item: newGoatCheeseShopItem).find_best_match

    assert_nil result
  end
end
