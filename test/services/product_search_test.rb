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

  test "results include uuid for each category" do
    service = ProductSearch.new(query: @query)
    results = service.results

    # Ensure all results have a uuid
    results.each do |category|
      assert category.respond_to?(:uuid), "Category does not have a uuid"
      assert_not_nil category.uuid, "Category uuid is nil"
    end
  end
end
