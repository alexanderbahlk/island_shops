# == Schema Information
#
# Table name: users
#
#  id                            :bigint           not null, primary key
#  app_hash                      :string
#  group_shopping_lists_items_by :string
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  active_shopping_list_id       :bigint
#
# Indexes
#
#  index_users_on_active_shopping_list_id  (active_shopping_list_id)
#
# Foreign Keys
#
#  fk_rails_...  (active_shopping_list_id => shopping_lists.id)
#
require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user_one = users(:user_one) # Assuming you have a fixture for users
    @user_two = users(:user_two)
  end

  test "should be valid" do
    assert @user_one.valid?
  end

  test "app_hash should be present" do
    @user_one.app_hash = nil
    assert_not @user_one.valid?
  end

  test "app_hash should be unique" do
    duplicate_user = @user_one.dup
    assert_not duplicate_user.valid?
  end

  test "group_shopping_lists_items_by should allow valid values" do
    valid_sorting_orders = ShoppingList::SHOPPING_LIST_GROUP_BY_ORDERS
    valid_sorting_orders.each do |valid_order|
      @user_one.group_shopping_lists_items_by = valid_order
      assert @user_one.valid?, "#{valid_order.inspect} should be valid"
      @user_two.group_shopping_lists_items_by = valid_order
      assert @user_two.valid?, "#{valid_order.inspect} should be valid"
    end
  end

  test "group_shopping_lists_items_by should reject invalid values" do
    invalid_sorting_orders = %w[ascending descending random nil_value]
    invalid_sorting_orders.each do |invalid_order|
      @user_one.group_shopping_lists_items_by = invalid_order
      assert_not @user_one.valid?, "#{invalid_order.inspect} should be invalid"
    end
  end

  test "group_shopping_lists_items_by should allow nil" do
    @user_one.group_shopping_lists_items_by = nil
    assert @user_one.valid?
  end

  test "is_new_user? should return true for new users" do
    new_user = User.create!(app_hash: "new_user_hash")
    assert new_user.is_new_user?
  end

  test "should delete user without deleting associated shop_items" do
    user = users(:user_one) # Assuming a fixture exists
    shop_item = shop_items(:shop_item_with_user) # Assuming a fixture exists

    assert_difference("User.count", -1) do
      user.destroy
    end

    shop_item.reload
    assert_nil shop_item.user_id
  end
end
