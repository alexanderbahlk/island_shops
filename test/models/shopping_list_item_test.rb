# == Schema Information
#
# Table name: shopping_list_items
#
#  id               :bigint           not null, primary key
#  title            :string           not null
#  uuid             :uuid             not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  category_id      :bigint
#  shopping_list_id :bigint           not null
#
# Indexes
#
#  index_shopping_list_items_on_category_id  (category_id)
#  index_shopping_list_items_on_uuid         (uuid) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (shopping_list_id => shopping_lists.id)
#
require "test_helper"

class ShoppingListItemTest < ActiveSupport::TestCase
  def setup
    @shopping_list = shopping_lists(:shopping_list_abc) # Assuming a fixture exists
    @category = categories(:milk) # Assuming a fixture exists for a product category
    @non_product_category = categories(:fresh_food) # Assuming a fixture exists for a non-product category
  end

  test "should be valid with a title and shopping list" do
    item = @shopping_list.shopping_list_items.build(title: "Milk")
    assert item.valid?
  end

  test "should set title from category if category exists" do
    item = @shopping_list.shopping_list_items.build(category: @category)
    assert item.valid?, "Validation failed: #{item.errors.full_messages}"
    assert_equal @category.title, item.title
  end

  test "should overwrite title if already set" do
    item = @shopping_list.shopping_list_items.build(title: "Custom Title", category: @category)
    assert item.valid?
    assert_equal "Milk", item.title
  end

  test "should require a title if no category is provided" do
    item = @shopping_list.shopping_list_items.build
    assert_not item.valid?
    assert_includes item.errors[:title], "can't be blank"
  end

  test "should require category to be of type product" do
    item = @shopping_list.shopping_list_items.build(category: @non_product_category)
    assert_not item.valid?
    assert_includes item.errors[:category], "must be a product category"
  end

  test "should allow category to be nil" do
    item = @shopping_list.shopping_list_items.build(title: "Custom Title")
    assert item.valid?
  end
end
