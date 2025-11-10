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

  test "should not match shampoo shop items at a specific threshold" do
    #just for the test
    shampooo_category = categories(:milk)
    shop_item = ShopItem.create!(
      title: "Herbal Ess Shampoo Herbal Essences Honey",
      url: "http://example.com/Herbal_Ess_Shampoo_Herbal_Essences_Honey",
      breadcrumb: "Home  >  Beauty & Personal Care  >  Hair Care  >  Shampoo",
      place: @place,
      category: shampooo_category,
      approved: true,
    )

    newShampooShopItem = ShopItem.new(
      title: "Inecto Shampoo Pure Coconut 16.9oz",
      url: "http://example.com/inector_shampoo_pure_coconut_16_9oz",
      breadcrumb: "Home  >  Beauty & Personal Care  >  Hair Care  >  Shampoo",
      place: @place,
    )
    result = ShopItemShopItemMatcher.new(shop_item: newShampooShopItem, sim: 0.15).find_best_match

    assert_equal shop_item.category, result
  end
end
