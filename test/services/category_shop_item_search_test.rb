require "test_helper"

class CategoryShopItemSearchTest < ActiveSupport::TestCase
  def setup
    @query = "milk"
  end

  test "returns empty array for blank query" do
    service = CategoryShopItemSearch.new(query: "")
    assert_equal [], service.results
  end

  test "returns categories with shop items for valid query" do
    service = CategoryShopItemSearch.new(query: @query)
    results = service.results
    assert results.is_a?(Array)
    assert results.first[:shop_items].is_a?(Array) if results.any?
  end

  test "respects hide_out_of_stock param" do
    service = CategoryShopItemSearch.new(query: @query, hide_out_of_stock: true)
    results = service.results
    results.each do |cat|
      cat[:shop_items].each do |item|
        refute_equal "out_of_stock", item[:stock_status]
      end
    end
  end

  test "limits shop items per category" do
    service = CategoryShopItemSearch.new(query: @query, limit: 2)
    results = service.results
    results.each do |cat|
      assert cat[:shop_items].size <= 2
    end
  end
end
