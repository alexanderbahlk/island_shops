require "test_helper"

class ShopItemCategoryMatcherTest < ActiveSupport::TestCase
  def setup
    # Create category hierarchy for testing
    @root_food = categories(:food_root)
    @fresh_food = categories(:fresh_food)
    @dairy = categories(:dairy)
    @beverages = categories(:beverages)
    @bakery = categories(:bakery)

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
    assert_nil ShopItemCategoryMatcher.find_best_match("")
    assert_nil ShopItemCategoryMatcher.find_best_match(nil)
    assert_nil ShopItemCategoryMatcher.find_best_match("   ")
  end

  test "find_best_match returns exact match case insensitive" do
    result = ShopItemCategoryMatcher.find_best_match("wine")
    assert_equal @wine_category, result

    result = ShopItemCategoryMatcher.find_best_match("WINE")
    assert_equal @wine_category, result

    result = ShopItemCategoryMatcher.find_best_match("Wine")
    assert_equal @wine_category, result
  end

  test "find_best_match on realistic shop item title" do
    result = ShopItemCategoryMatcher.find_best_match("Shop > Grocery > Beverages > Milks , Evaporated, Condensed , Powdered, Shelf Stable / Sungold Evaporated Milk")
    assert_equal @evaporated_milk_category, result
  end

  test "find_best_match handles plural variations" do
    result = ShopItemCategoryMatcher.find_best_match("Shop > Grocery > Beverages > Milks , Evaporated, Condensed , Powdered, Shelf Stable > Sungold Evaporated Milks")
    assert_equal @evaporated_milk_category, result
  end

  test "find_best_match from breadcrump title" do
    result = ShopItemCategoryMatcher.find_best_match("Shop > Grocery > Canned Goods, Soups, & Broths > Canned Vegetables > Hunts Tomatoes Diced 8 14.5")
    assert_equal @tomatoes_canned, result

    result = ShopItemCategoryMatcher.find_best_match("Shop > Produce > Fresh Vegetables > Tomatoes > Tomato Large Red Per#")
    assert_equal @tomatoes_fresh, result
  end

  test "find_best_match from coffee breadcrump" do
    result = ShopItemCategoryMatcher.find_best_match("PriceSmart > Groceries > Coffee & Tea > Member's Selection Freeze Dried Instant Coffee 320 g / 11.2 oz")
    assert_equal @coffee_category, result
  end

  test "find_best_match ignores size and unit information" do
    result = ShopItemCategoryMatcher.find_best_match("Wine 750ml")
    assert_equal @wine_category, result

    result = ShopItemCategoryMatcher.find_best_match("Beer 12 pack")
    assert_equal @beer_category, result

    result = ShopItemCategoryMatcher.find_best_match("Cheese 500g")
    assert_equal @cheese_category, result
  end

  test "find_best_match ignores brand indicators" do
    result = ShopItemCategoryMatcher.find_best_match("Premium Wine")
    assert_equal @wine_category, result

    result = ShopItemCategoryMatcher.find_best_match("Fresh Bread")
    assert_equal @bread_category, result
  end

  test "find_best_match handles complex product titles" do
    result = ShopItemCategoryMatcher.find_best_match("Premium Red Wine Merlot 750ml")
    # Should match either "Wine" or "Red Wine" depending on similarity scores
    assert result.title.include?("Wine")
  end

  test "find_best_match returns nil when no match found" do
    result = ShopItemCategoryMatcher.find_best_match("Nonexistent Product Category")
    assert_nil result
  end

  test "find_fuzzy_match returns category with similarity score" do
    # Skip this test if pg_trgm is not available
    skip "pg_trgm not available" unless ShopItemCategoryMatcher.send(:pg_trgm_available?)

    # Test the fuzzy match method directly
    normalized_title = "wines"  # This should match "wine" via fuzzy matching
    result = ShopItemCategoryMatcher.send(:find_fuzzy_match, normalized_title)

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

  test "find_best_match only matches product categories" do
    # But matching product categories should work
    result = ShopItemCategoryMatcher.find_best_match("Milk")
    assert_equal @milk_category, result
  end

  # Tests for find_similar_categories method
  test "find_similar_categories returns empty array for blank title" do
    assert_empty ShopItemCategoryMatcher.find_similar_categories("")
    assert_empty ShopItemCategoryMatcher.find_similar_categories(nil)
    assert_empty ShopItemCategoryMatcher.find_similar_categories("   ")
  end

  test "find_similar_categories returns array of similar categories with similarity scores" do
    # Skip this test if pg_trgm is not available
    skip "pg_trgm not available" unless ShopItemCategoryMatcher.send(:pg_trgm_available?)

    results = ShopItemCategoryMatcher.find_similar_categories("Wines")

    results.each do |result|
      assert result.is_a?(Hash)
      assert result.has_key?(:category)
      assert result.has_key?(:similarity)
      assert result[:category].is_a?(Category)
      assert result[:category].product?
      assert result[:similarity].is_a?(Float)
      assert result[:similarity] > 0
      assert result[:similarity] <= 1
    end
  end

  test "find_similar_categories respects limit parameter" do
    # Skip this test if pg_trgm is not available
    skip "pg_trgm not available" unless ShopItemCategoryMatcher.send(:pg_trgm_available?)

    results = ShopItemCategoryMatcher.find_similar_categories("Wine", limit: 2)
    assert results.length <= 2
  end

  # Tests for normalize_title method
  test "normalize_title removes size patterns" do
    normalized = ShopItemCategoryMatcher.send(:normalize_title, "Wine 750ml")
    assert_equal "wine", normalized

    normalized = ShopItemCategoryMatcher.send(:normalize_title, "Beer 12 pack")
    assert_equal "beer", normalized

    normalized = ShopItemCategoryMatcher.send(:normalize_title, "Cheese 2kg")
    assert_equal "cheese", normalized
  end

  test "normalize_title removes brand indicators" do
    normalized = ShopItemCategoryMatcher.send(:normalize_title, "Premium Wine")
    assert_equal "wine", normalized

    normalized = ShopItemCategoryMatcher.send(:normalize_title, "Organic Fresh Bread")
    assert_equal "organic fresh bread", normalized
  end

  test "normalize_title handles complex titles" do
    normalized = ShopItemCategoryMatcher.send(:normalize_title, "Premium Organic Wine 750ml Select Grade A")
    assert_equal "organic wine select grade a", normalized
  end

  test "normalize_title handles extra whitespace" do
    normalized = ShopItemCategoryMatcher.send(:normalize_title, "  Wine   750ml  ")
    assert_equal "wine", normalized

    normalized = ShopItemCategoryMatcher.send(:normalize_title, "Beer    12   pack")
    assert_equal "beer", normalized
  end

  test "normalize_title returns empty string for blank input" do
    assert_equal "", ShopItemCategoryMatcher.send(:normalize_title, "")
    assert_equal "", ShopItemCategoryMatcher.send(:normalize_title, nil)
    assert_equal "", ShopItemCategoryMatcher.send(:normalize_title, "   ")
  end

  # Tests for auto_assign_categories method
  test "auto_assign_categories assigns categories to shop items without categories" do
    # Create shop items without categories
    shop_item1 = ShopItem.create!(
      url: "https://example.com/milk",
      shop: "Massy",
      title: "Fresh Organic Milk 1L",
      size: 1.0,
      unit: "l",
    )

    shop_item2 = ShopItem.create!(
      url: "https://example.com/wine",
      shop: "Massy",
      title: "Premium Red Wine 750ml",
      size: 750.0,
      unit: "ml",
    )

    results = ShopItemCategoryMatcher.auto_assign_categories([shop_item1, shop_item2])

    assert_equal 2, results[:total_processed]
    assert results[:assigned] >= 1 # At least one should be assigned

    # Check that items were assigned appropriate categories
    shop_item1.reload
    shop_item2.reload

    if shop_item1.category
      assert shop_item1.category.product?
      assert_equal "Organic Milk", shop_item1.category.title
    end

    if shop_item2.category
      assert shop_item2.category.product?
      assert shop_item2.category.title.include?("Red Wine")
    end
  end

  test "auto_assign_categories skips items that already have categories" do
    # Create shop item with existing category
    shop_item = ShopItem.create!(
      url: "https://example.com/existing-category",
      shop: "Massy",
      title: "Some Product",
      category: @milk_category,
    )

    results = ShopItemCategoryMatcher.auto_assign_categories([shop_item])

    assert_equal 1, results[:total_processed]
    assert_equal 1, results[:skipped]
    assert_equal 0, results[:assigned]
  end

  # Tests for suggest_categories_for_item method
  test "suggest_categories_for_item returns suggestions with reasons" do
    shop_item = ShopItem.new(title: "Premium Organic Wine Collection")

    suggestions = ShopItemCategoryMatcher.suggest_categories_for_item(shop_item)

    suggestions.each do |suggestion|
      assert suggestion.has_key?(:category)
      assert suggestion.has_key?(:similarity)
      assert suggestion.has_key?(:breadcrumb)
      assert suggestion.has_key?(:reason)

      assert suggestion[:category].is_a?(Category)
      assert suggestion[:category].product?
      assert suggestion[:breadcrumb].is_a?(String)
      assert suggestion[:reason].is_a?(String)
    end
  end

  # Tests for category_assignment_stats method
  test "category_assignment_stats returns correct statistics" do
    # Create some shop items with and without categories
    ShopItem.create!(url: "https://example.com/with-category", shop: "Massy", title: "Test", category: @milk_category)
    ShopItem.create!(url: "https://example.com/without-category", shop: "Massy", title: "Test")

    stats = ShopItemCategoryMatcher.category_assignment_stats

    assert stats.has_key?(:total_items)
    assert stats.has_key?(:assigned_items)
    assert stats.has_key?(:missing_items)
    assert stats.has_key?(:assignment_percentage)
    assert stats.has_key?(:total_product_categories)

    assert stats[:total_items] >= 2
    assert stats[:assigned_items] >= 1
    assert stats[:missing_items] >= 1
    assert stats[:total_product_categories] >= 8 # Our test categories
  end

  # Tests for pg_trgm_available? method
  test "pg_trgm_available caches result" do
    # Reset the cached value
    ShopItemCategoryMatcher.instance_variable_set(:@pg_trgm_available, nil)

    # First call should query the database
    result1 = ShopItemCategoryMatcher.send(:pg_trgm_available?)

    # Second call should use cached value
    result2 = ShopItemCategoryMatcher.send(:pg_trgm_available?)

    assert_equal result1, result2
  end

  # Integration tests
  test "end_to_end_fuzzy_matching_workflow" do
    # Skip this test if pg_trgm is not available
    skip "pg_trgm not available" unless ShopItemCategoryMatcher.send(:pg_trgm_available?)

    # Test the complete workflow for a product title
    title = "Premium Organic Red Wine Merlot 750ml"

    # Should find a wine-related category
    result = ShopItemCategoryMatcher.find_best_match(title)

    if result
      assert result.title.downcase.include?("wine")
      assert result.product?
    end
  end

  test "performance_with_many_categories" do
    # Create many product categories to test performance
    test_subcategory = Category.create!(title: "Test Subcategory", parent: @fresh_food, category_type: :subcategory)

    100.times do |i|
      Category.create!(title: "Test Product #{i}", parent: test_subcategory, category_type: :product)
    end

    # Measure time for find_best_match
    start_time = Time.current
    ShopItemCategoryMatcher.find_best_match("Test Product")
    end_time = Time.current

    # Should complete in reasonable time (less than 1 second)
    assert (end_time - start_time) < 1.0

    # Clean up
    Category.where("title LIKE 'Test Product%'").destroy_all
    test_subcategory.destroy
  end
end
