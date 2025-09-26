require "test_helper"

class CategoryBreadcrumbHelperTest < ActiveSupport::TestCase
  include CategoryBreadcrumbHelper

  def setup
    @root_category = categories(:food_root) # Root category
    @category = categories(:fresh_food) # Child of root
    @subcategory = categories(:dairy) # Child of fresh_food
    @product_category = categories(:milk) # Child of dairy
  end

  test "build_breadcrumb_by_uuid returns breadcrumb for valid uuid" do
    breadcrumb = build_breadcrumb_by_uuid(@product_category.uuid)
    assert_equal [@root_category.title, @category.title, @subcategory.title], breadcrumb
  end

  test "build_breadcrumb_by_uuid returns empty array for invalid uuid" do
    breadcrumb = build_breadcrumb_by_uuid("invalid-uuid")
    assert_equal [], breadcrumb
  end

  test "build_breadcrumb returns breadcrumb for valid category" do
    breadcrumb = build_breadcrumb(@product_category)
    assert_equal [@root_category.title, @category.title, @subcategory.title], breadcrumb
  end

  test "build_breadcrumb handles category without parent" do
    breadcrumb = build_breadcrumb(@root_category)
    assert_equal [], breadcrumb
  end

  test "build_breadcrumb handles invalid category gracefully" do
    breadcrumb = build_breadcrumb(nil)
    assert_equal [], breadcrumb
  end
end
