require "test_helper"

class ProductSearchTest < ActiveSupport::TestCase
  def setup
    @query = "milk"
  end

  test "returns empty array for blank query" do
    service = ProductSearch.new(query: "")
    assert_equal [], service.results
  end

  test "returns milk category for synonym query" do
    service = ProductSearch.new(query: @query)
    results = service.results
    assert_equal results.size, 3
    #check all items in array
    assert_equal results.map { |cat| cat[:title] }, ["Milk", "Organic Milk", "Evaporated Milk"]
  end
end
