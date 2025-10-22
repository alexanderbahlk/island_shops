# == Schema Information
#
# Table name: shopping_list_items
#
#  id               :bigint           not null, primary key
#  deleted_at       :datetime
#  priority         :boolean          default(FALSE), not null
#  purchased        :boolean          default(FALSE), not null
#  quantity         :integer          default(1), not null
#  title            :string           not null
#  uuid             :uuid             not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  category_id      :bigint
#  shop_item_id     :bigint
#  shopping_list_id :bigint           not null
#  user_id          :bigint
#
# Indexes
#
#  index_shopping_list_items_on_category_id   (category_id)
#  index_shopping_list_items_on_deleted_at    (deleted_at)
#  index_shopping_list_items_on_shop_item_id  (shop_item_id)
#  index_shopping_list_items_on_user_id       (user_id)
#  index_shopping_list_items_on_uuid          (uuid) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (shop_item_id => shop_items.id)
#  fk_rails_...  (shopping_list_id => shopping_lists.id)
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
require "test_helper"

class ShoppingListItemTest < ActiveSupport::TestCase
  def setup
    @shopping_list = shopping_lists(:shopping_list_abc) # Assuming a fixture exists
    @category = categories(:milk) # Assuming a fixture exists for a product category
    @non_product_category = categories(:fresh_food) # Assuming a fixture exists for a non-product category
    @shopping_list_item = shopping_list_items(:shopping_list_item_milk) # Assuming a fixture exists for a shopping list item
    @user = users(:user_one) # Assuming a fixture exists
  end

  test "should be valid with a title and shopping list" do
    item = @shopping_list.shopping_list_items.build(title: "Milk", user: @user)
    assert item.valid?
  end

  test "should set title from category if category exists" do
    item = @shopping_list.shopping_list_items.build(category: @category, user: @user)
    assert item.valid?, "Validation failed: #{item.errors.full_messages}"
    item.save
    assert item.uuid.present?, "UUID should be present"
    assert_equal @category.title, item.title
  end

  test "should have uuid present and unique" do
    item = @shopping_list.shopping_list_items.build(title: "Milk", user: @user)
    assert item.valid?
    item.save
    assert item.uuid.present?, "UUID should be present"

    duplicate = @shopping_list.shopping_list_items.build(title: "Duplicate Milk", user: @user, uuid: item.uuid)
    assert_not duplicate.valid?

    assert_includes duplicate.errors[:uuid], "has already been taken"
  end

  test "should overwrite title if already set" do
    item = @shopping_list.shopping_list_items.build(title: "Custom Title", category: @category, user: @user)
    assert item.valid?
    assert_equal "Milk", item.title
  end

  test "should require a title if no category is provided" do
    item = @shopping_list.shopping_list_items.build
    assert_not item.valid?
    assert_includes item.errors[:title], "can't be blank"
  end

  test "should require category to be of type product" do
    item = @shopping_list.shopping_list_items.build(category: @non_product_category, user: @user)
    assert_not item.valid?
    assert_includes item.errors[:category], "must be a product category"
  end

  test "should allow category to be nil" do
    item = @shopping_list.shopping_list_items.build(title: "Custom Title", user: @user)
    assert item.valid?
  end

  test "should have purchased default to false" do
    new_item = ShoppingListItem.new(title: "Eggs", shopping_list: shopping_lists(:shopping_list_cde))
    assert_not new_item.purchased
  end

  test "should allow purchased to be updated" do
    @shopping_list_item.update!(purchased: true)
    assert @shopping_list_item.purchased
  end

  test "should have quantity default to 1" do
    new_item = ShoppingListItem.new(title: "Eggs", shopping_list: shopping_lists(:shopping_list_abc))
    assert_equal 1, new_item.quantity
  end

  test "should not allow quantity less than 1" do
    @shopping_list_item.quantity = 0
    assert_not @shopping_list_item.valid?
    assert_includes @shopping_list_item.errors[:quantity], "must be greater than 0"
  end

  test "should allow quantity to be updated" do
    @shopping_list_item.update!(quantity: 5)
    assert_equal 5, @shopping_list_item.quantity
  end

  test "should have valid shopping list item after user was deleted" do
    assert @shopping_list_item.user.present?

    @user.destroy
    @shopping_list_item.reload

    assert_nil @shopping_list_item.user
    assert @shopping_list_item.valid?
  end
end
