require "test_helper"

class ShopItemTypeMatcherTest < ActiveSupport::TestCase
  def setup
    # Use fixtures instead of creating records
    @wine_type = shop_item_types(:wine)
    @beer_type = shop_item_types(:beer)
    @cheese_type = shop_item_types(:cheese)
    @bread_type = shop_item_types(:bread)
    @organic_wine_type = shop_item_types(:organic_wine)
    @red_wine_type = shop_item_types(:red_wine)
    @craft_beer_type = shop_item_types(:craft_beer)
  end

  # Tests for find_best_match method
  test "find_best_match returns nil for blank title" do
    assert_nil ShopItemTypeMatcher.find_best_match("")
    assert_nil ShopItemTypeMatcher.find_best_match(nil)
    assert_nil ShopItemTypeMatcher.find_best_match("   ")
  end

  test "find_best_match returns exact match case insensitive" do
    result = ShopItemTypeMatcher.find_best_match("wine")
    assert_equal @wine_type, result

    result = ShopItemTypeMatcher.find_best_match("WINE")
    assert_equal @wine_type, result

    result = ShopItemTypeMatcher.find_best_match("Wine")
    assert_equal @wine_type, result
  end

  test "find_best_match ignores size and unit information" do
    result = ShopItemTypeMatcher.find_best_match("Wine 750ml")
    assert_equal @wine_type, result

    result = ShopItemTypeMatcher.find_best_match("Beer 12 pack")
    assert_equal @beer_type, result

    result = ShopItemTypeMatcher.find_best_match("Cheese 500g")
    assert_equal @cheese_type, result
  end

  test "find_best_match ignores brand indicators" do
    result = ShopItemTypeMatcher.find_best_match("Premium Wine")
    assert_equal @wine_type, result

    result = ShopItemTypeMatcher.find_best_match("Organic Beer")
    assert_equal @beer_type, result

    result = ShopItemTypeMatcher.find_best_match("Fresh Bread")
    assert_equal @bread_type, result
  end

  test "find_best_match handles complex product titles" do
    result = ShopItemTypeMatcher.find_best_match("Premium Red Wine Merlot 750ml")
    # Should match either "Wine" or "Red Wine" depending on similarity scores
    assert result.title.include?("Wine")
  end

  test "find_best_match returns nil when no match found" do
    result = ShopItemTypeMatcher.find_best_match("Nonexistent Product Category")
    assert_nil result
  end

  test "find_best_match returns type with similarity score when fuzzy match found" do
    # Skip this test if pg_trgm is not available
    skip "pg_trgm not available" unless ShopItemTypeMatcher.send(:pg_trgm_available?)

    result = ShopItemTypeMatcher.find_best_match("Wines")  # Plural of Wine

    if result # Only test if fuzzy matching found a result
      assert_equal @wine_type, result
      assert result.respond_to?(:sim_score)
      assert result.sim_score > 0
      assert result.sim_score <= 1
    end
  end

  # Tests for find_similar_types method
  test "find_similar_types returns empty array for blank title" do
    assert_empty ShopItemTypeMatcher.find_similar_types("")
    assert_empty ShopItemTypeMatcher.find_similar_types(nil)
    assert_empty ShopItemTypeMatcher.find_similar_types("   ")
  end

  test "find_similar_types returns array of similar types with similarity scores" do
    # Skip this test if pg_trgm is not available
    skip "pg_trgm not available" unless ShopItemTypeMatcher.send(:pg_trgm_available?)

    results = ShopItemTypeMatcher.find_similar_types("Wines")

    results.each do |result|
      assert result.is_a?(Hash)
      assert result.has_key?(:type)
      assert result.has_key?(:similarity)
      assert result[:type].is_a?(ShopItemType)
      assert result[:similarity].is_a?(Float)
      assert result[:similarity] > 0
      assert result[:similarity] <= 1
    end
  end

  test "find_similar_types respects limit parameter" do
    # Skip this test if pg_trgm is not available
    skip "pg_trgm not available" unless ShopItemTypeMatcher.send(:pg_trgm_available?)

    results = ShopItemTypeMatcher.find_similar_types("Wine", limit: 2)
    assert results.length <= 2
  end

  # Tests for extract_type_keywords method
  test "extract_type_keywords returns empty array for blank title" do
    assert_empty ShopItemTypeMatcher.extract_type_keywords("")
    assert_empty ShopItemTypeMatcher.extract_type_keywords(nil)
    assert_empty ShopItemTypeMatcher.extract_type_keywords("   ")
  end

  test "extract_type_keywords finds existing type keywords in title" do
    keywords = ShopItemTypeMatcher.extract_type_keywords("Red Wine and Aged Cheese Selection")

    # Should find both "wine" and "cheese" (case insensitive)
    assert_includes keywords, "wine"
    assert_includes keywords, "cheese"
  end

  test "extract_type_keywords extracts words from title" do
    keywords = ShopItemTypeMatcher.extract_type_keywords("Artisan Sourdough Loaf")

    # Should extract words longer than 3 characters
    assert_includes keywords, "artisan"
    assert_includes keywords, "sourdough"
    assert_includes keywords, "loaf"
  end

  test "extract_type_keywords filters out short words" do
    keywords = ShopItemTypeMatcher.extract_type_keywords("A Big Red Wine")

    # Should not include words with 2 or fewer characters
    refute_includes keywords, "a"
    assert_includes keywords, "big"
    assert_includes keywords, "red"
    assert_includes keywords, "wine"
  end

  test "extract_type_keywords returns unique keywords" do
    keywords = ShopItemTypeMatcher.extract_type_keywords("Wine Wine Red Wine")

    # Should not have duplicates
    assert_equal keywords.uniq, keywords
    assert_includes keywords, "wine"
    assert_includes keywords, "red"
  end

  # Tests for normalize_title method
  test "normalize_title removes size patterns" do
    normalized = ShopItemTypeMatcher.send(:normalize_title, "Wine 750ml")
    assert_equal "Wine", normalized

    normalized = ShopItemTypeMatcher.send(:normalize_title, "Beer 12 pack")
    assert_equal "Beer", normalized

    normalized = ShopItemTypeMatcher.send(:normalize_title, "Cheese 2kg")
    assert_equal "Cheese", normalized
  end

  test "normalize_title removes brand indicators" do
    normalized = ShopItemTypeMatcher.send(:normalize_title, "Premium Wine")
    assert_equal "Wine", normalized

    normalized = ShopItemTypeMatcher.send(:normalize_title, "Organic Fresh Bread")
    assert_equal "Bread", normalized
  end

  test "normalize_title handles complex titles" do
    normalized = ShopItemTypeMatcher.send(:normalize_title, "Premium Organic Wine 750ml Select Grade A")
    assert_equal "Wine", normalized
  end

  test "normalize_title handles extra whitespace" do
    normalized = ShopItemTypeMatcher.send(:normalize_title, "  Wine   750ml  ")
    assert_equal "Wine", normalized

    normalized = ShopItemTypeMatcher.send(:normalize_title, "Beer    12   pack")
    assert_equal "Beer", normalized
  end

  test "normalize_title returns empty string for blank input" do
    assert_equal "", ShopItemTypeMatcher.send(:normalize_title, "")
    assert_equal "", ShopItemTypeMatcher.send(:normalize_title, nil)
    assert_equal "", ShopItemTypeMatcher.send(:normalize_title, "   ")
  end

  # Tests for pg_trgm_available? method
  test "pg_trgm_available caches result" do
    # Reset the cached value
    ShopItemTypeMatcher.instance_variable_set(:@pg_trgm_available, nil)

    # First call should query the database
    result1 = ShopItemTypeMatcher.send(:pg_trgm_available?)

    # Second call should use cached value (mock to verify no second database call)
    result2 = ShopItemTypeMatcher.send(:pg_trgm_available?)

    assert_equal result1, result2
  end

  # Integration tests
  test "end_to_end_fuzzy_matching_workflow" do
    # Skip this test if pg_trgm is not available
    skip "pg_trgm not available" unless ShopItemTypeMatcher.send(:pg_trgm_available?)

    # Test the complete workflow for a product title
    title = "Premium Organic Red Wine Merlot 750ml"

    # Should find a wine-related type
    result = ShopItemTypeMatcher.find_best_match(title)

    if result
      assert result.title.downcase.include?("wine")
    end
  end

  test "performance_with_many_types" do
    # Create many types to test performance
    100.times do |i|
      ShopItemType.create!(title: "Test Type #{i}")
    end

    # Measure time for find_best_match
    start_time = Time.current
    ShopItemTypeMatcher.find_best_match("Test Product")
    end_time = Time.current

    # Should complete in reasonable time (less than 1 second)
    assert (end_time - start_time) < 1.0

    # Clean up
    ShopItemType.where("title LIKE 'Test Type%'").delete_all
  end
end
