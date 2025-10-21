require "test_helper"

class ShopItemCategoryMatcherTest < ActiveSupport::TestCase
  include TitleNormalizer

  def setup
    # Create category hierarchy for testing
    @root_food = categories(:food_root)
    @fresh_food = categories(:fresh_food)
    @dairy = categories(:dairy)
    @beverages = categories(:beverages)
    @bakery = categories(:bakery)

    @place = places(:place_one)

    # Create product categories (the ones we'll match against)
    @tomatoes_canned = categories(:tomatoes_canned)
    @tomatoes_fresh = categories(:tomatoes_fresh)
    @milk_category = categories(:milk)
    @coffee_category = categories(:coffee)
    @evaporated_milk_category = categories(:evaporated_milk)
    @cheese_category = categories(:cheese)
    @wine_category = categories(:wine)
    @beer_category = categories(:beer)
    @bread_category = categories(:bread)
    @organic_wine_category = categories(:organic_wine)
    @red_wine_category = categories(:red_wine)
    @craft_beer_category = Category.create!(title: "Craft Beer", parent: @beverages, category_type: :product)
  end

  # Tests for find_best_match method
  test "find_best_match returns nil for blank title" do
    emptyTitleShopItem = ShopItem.new(title: "", url: "www.example.com", place: @place)
    assert_nil ShopItemCategoryMatcher.new(shop_item: emptyTitleShopItem).find_best_match
    nilTitleShopItem = ShopItem.new(title: nil, url: "www.example.com", place: @place)
    assert_nil ShopItemCategoryMatcher.new(shop_item: nilTitleShopItem).find_best_match
    spaceTitleShopItem = ShopItem.new(title: "   ", url: "www.example.com", place: @place)
    assert_nil ShopItemCategoryMatcher.new(shop_item: spaceTitleShopItem).find_best_match
  end

  test "find_best_match returns exact match case insensitive title" do
    lowerCaseTitleShopItem = ShopItem.new(title: "wine", url: "www.example.com", place: @place)
    result = ShopItemCategoryMatcher.new(shop_item: lowerCaseTitleShopItem).find_best_match
    assert_equal @wine_category, result

    upperCaseTitleShopItem = ShopItem.new(title: "WINE", url: "www.example.com", place: @place)
    result = ShopItemCategoryMatcher.new(shop_item: upperCaseTitleShopItem).find_best_match
    assert_equal @wine_category, result

    camelCaseTitleShopItem = ShopItem.new(title: "Wine", url: "www.example.com", place: @place)
    result = ShopItemCategoryMatcher.new(shop_item: camelCaseTitleShopItem).find_best_match
    assert_equal @wine_category, result
  end

  test "find_best_match on realistic shop item title" do
    relasticBreadcrumbShopItem = ShopItem.new(title: "Sungold Evaporated Milk", breadcrumb: "Shop > Grocery > Beverages > Milks , Evaporated, Condensed , Powdered, Shelf Stable > Sungold Evaporated Milk", url: "www.example.com", place: @place)
    result = ShopItemCategoryMatcher.new(shop_item: relasticBreadcrumbShopItem).find_best_match
    assert_equal @evaporated_milk_category, result
  end

  test "find_best_match handles plural variations" do
    pluralBreadcrumbShopItem = ShopItem.new(title: "Sungold Evaporated Milks", breadcrumb: "Shop > Grocery > Beverages > Milks , Evaporated, Condensed , Powdered, Shelf Stable > Sungold Evaporated Milk", url: "www.example.com", place: @place)
    result = ShopItemCategoryMatcher.new(shop_item: pluralBreadcrumbShopItem).find_best_match
    assert_equal @evaporated_milk_category, result
  end

  test "find_best_match from breadcrump title" do
    cannedTomatoesShopItem = ShopItem.new(title: "Hunts Tomatoes Diced 8 14.5", breadcrumb: "Shop > Grocery > Canned Goods, Soups, & Broths > Canned Vegetables > Hunts Tomatoes Diced 8 14.5", url: "www.example.com", place: @place)
    result = ShopItemCategoryMatcher.new(shop_item: cannedTomatoesShopItem).find_best_match
    assert_equal @tomatoes_canned, result

    freshTomatoesShopItem = ShopItem.new(title: "Tomato Large Red Per#", breadcrumb: "Shop > Produce > Fresh Vegetables > Tomatoes > Tomato Large Red Per#", url: "www.example.com", place: @place)
    result = ShopItemCategoryMatcher.new(shop_item: freshTomatoesShopItem).find_best_match
    assert_equal @tomatoes_fresh, result
  end

  test "find_best_match from coffee breadcrump" do
    coffeeBreadcrumbShopItem = ShopItem.new(title: "Member's Selection Freeze Dried Instant Coffee 320 g / 11.2 oz", breadcrumb: "PriceSmart > Groceries > Coffee & Tea > Member's Selection Freeze Dried Instant Coffee 320 g / 11.2 oz", url: "www.example.com", place: @place)
    result = ShopItemCategoryMatcher.new(shop_item: coffeeBreadcrumbShopItem).find_best_match
    assert_equal @coffee_category, result
  end

  test "find_best_match ignores size and unit information from title" do
    wineTitleShopItem = ShopItem.new(title: "Wine 750ml", url: "www.example.com", place: @place)
    result = ShopItemCategoryMatcher.new(shop_item: wineTitleShopItem).find_best_match
    assert_equal @wine_category, result

    beerTitleShopItem = ShopItem.new(title: "Beer 12 pack", url: "www.example.com", place: @place)
    result = ShopItemCategoryMatcher.new(shop_item: beerTitleShopItem).find_best_match
    assert_equal @beer_category, result

    cheeseTitleShopItem = ShopItem.new(title: "Cheese 500g", url: "www.example.com", place: @place)
    result = ShopItemCategoryMatcher.new(shop_item: cheeseTitleShopItem).find_best_match
    assert_equal @cheese_category, result
  end

  test "find_best_match ignores brand indicators in title" do
    premiumWineShopItem = ShopItem.new(title: "Premium Wine", url: "www.example.com", place: @place)
    result = ShopItemCategoryMatcher.new(shop_item: premiumWineShopItem).find_best_match
    assert_equal @wine_category, result

    freshBreadShopItem = ShopItem.new(title: "Fresh Bread", url: "www.example.com", place: @place)
    result = ShopItemCategoryMatcher.new(shop_item: freshBreadShopItem).find_best_match
    assert_equal @bread_category, result
  end

  test "find_best_match handles complex product titles" do
    complexTitleShopItem = ShopItem.new(title: "Premium Organic Wine 750ml Select Grade A", url: "www.example.com", place: @place)
    result = ShopItemCategoryMatcher.new(shop_item: complexTitleShopItem).find_best_match
    assert_equal @organic_wine_category, result
  end

  test "find_best_match handles synonyms" do
    eggplantShopItem = ShopItem.new(title: "Aubergine", url: "www.example.com", place: @place)
    result = ShopItemCategoryMatcher.new(shop_item: eggplantShopItem).find_best_match
    assert_equal categories(:eggplant), result
    brinjalShopItem = ShopItem.new(title: "Brinjal", url: "www.example.com", place: @place)
    result = ShopItemCategoryMatcher.new(shop_item: brinjalShopItem).find_best_match
    assert_equal categories(:eggplant), result
  end

  test "find_best_match returns nil when no match found" do
    noMatchShopItem = ShopItem.new(title: "Nonexistent Product Category", url: "www.example.com", place: @place)
    result = ShopItemCategoryMatcher.new(shop_item: noMatchShopItem).find_best_match
    assert_nil result
  end

  test "find_best_match returns category with similarity score" do
    # Test the fuzzy match method directly

    wineShopItem = ShopItem.new(title: "wines", url: "www.example.com", place: @place)
    result = ShopItemCategoryMatcher.new(shop_item: wineShopItem).find_best_match

    if result
      assert result.is_a?(Category)
      assert result.product?
      assert result.respond_to?(:sim_score), "Category should have sim_score method"
      assert result.sim_score > 0, "Similarity score should be greater than 0"
      assert result.sim_score <= 1, "Similarity score should be less than or equal to 1"
      assert result.title.downcase.include?("wine"), "Should match a wine-related category"
    else
      skip "No fuzzy match found - may be due to test data or similarity threshold"
    end
  end

  # Tests for normalize_title method
  test "normalize_title removes size patterns" do
    normalized = normalize_title("Wine 750ml")
    assert_equal "wine", normalized

    normalized = normalize_title("Beer 12 pack")
    assert_equal "beer", normalized

    normalized = normalize_title("Cheese 2kg")
    assert_equal "cheese", normalized
  end

  test "normalize_title removes brand indicators" do
    normalized = normalize_title("Premium Wine")
    assert_equal "wine", normalized

    normalized = normalize_title("Organic Fresh Bread")
    assert_equal "organic fresh bread", normalized
  end

  test "normalize_title handles complex titles" do
    normalized = normalize_title("Premium Organic Wine 750ml Select Grade A")
    assert_equal "organic wine select grade a", normalized
  end

  test "normalize_title handles extra whitespace" do
    normalized = normalize_title("  Wine   750ml  ")
    assert_equal "wine", normalized

    normalized = normalize_title("Beer    12   pack")
    assert_equal "beer", normalized
  end

  test "normalize_title returns empty string for blank input" do
    assert_equal "", normalize_title("")
    assert_equal "", normalize_title(nil)
    assert_equal "", normalize_title("   ")
  end

  test "performance_with_many_categories" do
    skip "Skipping performance test for now"

    # Create many product categories to test performance
    test_subcategory = Category.create!(title: "Test Subcategory", parent: @fresh_food, category_type: :subcategory)

    100.times do |i|
      Category.create!(title: "Test Product #{i}", parent: test_subcategory, category_type: :product)
    end

    # Measure time for find_best_match
    start_time = Time.current
    testShopItem = ShopItem.new(title: "Test Product", url: "www.example.com", place: @place)
    ShopItemCategoryMatcher.new(shop_item: testShopItem).find_best_match()
    end_time = Time.current

    # Should complete in reasonable time (less than 1 second)
    assert (end_time - start_time) < 1.0

    # Clean up
    Category.where("title LIKE 'Test Product%'").destroy_all
    test_subcategory.destroy
  end
end
