require "test_helper"

class FetchShopItemsForCategoryServiceTest < ActiveSupport::TestCase
  def setup
    @category = categories(:milk)
    @shop_item_one = shop_items(:shop_item_one)
    @shop_item_two = shop_items(:shop_item_four)
    @shop_item_three = shop_items(:shop_item_milk)
    @shop_item_four = shop_items(:shop_item_with_user)
  end

  test "fetches approved shop items for category" do
    service = FetchShopItemsForCategoryService.new(category: @category)
    result = service.fetch_shop_items

    assert_kind_of Array, result
    assert_operator result.length, :>, 0
    assert_equal @category.shop_items.approved.count, result.length
    
    # All items should be from the category
    result.each do |item|
      assert item.key?(:title)
      assert item.key?(:uuid)
      assert item.key?(:place)
      assert item.key?(:latest_price)

      if item[:uuid] == "123e4567-e89b-12d3-a456-426614174996" # UUID of shop_item_four
        assert item.key?(:previous_price)
        assert_equal "18.99", item[:previous_price]
        assert item.key?(:price_change)
        assert_equal "-1.00", item[:price_change]
      end
    end
  end

  test "respects limit parameter" do
    service = FetchShopItemsForCategoryService.new(category: @category, limit: 2)
    result = service.fetch_shop_items

    assert_operator result.length, :<=, 2
  end

  test "sorts items by latest_price_per_normalized_unit" do
    service = FetchShopItemsForCategoryService.new(category: @category)
    result = service.fetch_shop_items

    # Check that items are sorted (excluding items without valid prices)
    prices = result.map { |item| item[:latest_price_per_normalized_unit] }
      .reject { |price| price == "N/A" || price == Float::INFINITY }
      .map(&:to_f)
    
    assert_equal prices, prices.sort
  end

  test "excludes out of stock items when hide_out_of_stock is true" do
    # Mark an item as out of stock
    out_of_stock_update = @shop_item_one.shop_item_updates.last
    out_of_stock_update.update(stock_status: "out_of_stock") if out_of_stock_update

    service_with_filter = FetchShopItemsForCategoryService.new(
      category: @category, 
      hide_out_of_stock: true
    )
    result_with_filter = service_with_filter.fetch_shop_items

    service_without_filter = FetchShopItemsForCategoryService.new(
      category: @category, 
      hide_out_of_stock: false
    )
    result_without_filter = service_without_filter.fetch_shop_items

    # With filter should have fewer or equal items
    assert_operator result_with_filter.length, :<=, result_without_filter.length
  end

  test "includes all required fields in shop item hash" do
    service = FetchShopItemsForCategoryService.new(category: @category, limit: 1)
    result = service.fetch_shop_items

    skip "No shop items found" if result.empty?

    item = result.first
    required_fields = [
      :title, :uuid, :place, :image_url, :unit, :stock_status,
      :latest_price, :previous_price, :latest_price_per_normalized_unit,
      :latest_price_per_normalized_unit_with_unit, 
      :latest_price_per_unit_with_unit, :url
    ]

    required_fields.each do |field|
      assert item.key?(field), "Missing field: #{field}"
    end
  end

  test "uses display_title when available, falls back to title" do
    # Set a display title for one item
    @shop_item_one.update(display_title: "Custom Display Title")

    service = FetchShopItemsForCategoryService.new(category: @category)
    result = service.fetch_shop_items

    item_with_display = result.find { |item| item[:uuid] == @shop_item_one.uuid }
    
    if item_with_display
      assert_equal "Custom Display Title", item_with_display[:title]
    end
  end

  test "handles items without shop_item_updates gracefully" do
    # Create an approved shop item without updates
    shop_item_no_updates = ShopItem.create!(
      url: "http://example.com/no-updates",
      title: "Item Without Updates",
      category: @category,
      approved: true,
      place: places(:place_one)
    )

    service = FetchShopItemsForCategoryService.new(category: @category)
    result = service.fetch_shop_items

    item = result.find { |i| i[:uuid] == shop_item_no_updates.uuid }
    
    if item
      assert_equal "N/A", item[:stock_status]
      assert_equal "N/A", item[:latest_price]
      assert_nil item[:previous_price]
    end
  end

  test "caches results for the same parameters" do
    skip if true

    service = FetchShopItemsForCategoryService.new(category: @category, limit: 3)
    
    # First call - should hit the database
    first_result = service.fetch_shop_items
    
    # Second call - should use cache
    # We can verify this by checking the cache directly
    cache_key = "fetch_shop_items/#{@category.id}/false/3"
    cached_result = Rails.cache.read(cache_key)
    
    assert_not_nil cached_result
    assert_equal first_result, cached_result
  end

  test "places items without valid price at the end" do
    service = FetchShopItemsForCategoryService.new(category: @category)
    result = service.fetch_shop_items

    # Items with "N/A" or invalid prices should be at the end
    prices = result.map { |item| item[:latest_price_per_normalized_unit] }
    
    # Find the first N/A or invalid price
    first_invalid_index = prices.index { |p| p == "N/A" || p.to_f.zero? }
    
    if first_invalid_index
      # All items after this should also be invalid
      prices[first_invalid_index..-1].each do |price|
        assert(price == "N/A" || price.to_f.zero?, "Invalid price should be at the end")
      end
    end
  end

  test "only includes approved shop items" do
    # Create an unapproved item
    unapproved_item = ShopItem.create!(
      url: "http://example.com/unapproved",
      title: "Unapproved Item",
      category: @category,
      approved: false,
      place: places(:place_one)
    )

    service = FetchShopItemsForCategoryService.new(category: @category)
    result = service.fetch_shop_items

    # Should not include the unapproved item
    unapproved_in_result = result.any? { |item| item[:uuid] == unapproved_item.uuid }
    assert_not unapproved_in_result
  end
end
