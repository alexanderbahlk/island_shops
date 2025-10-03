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

  test "sorting_order should allow valid values" do
    valid_sorting_orders = ShoppingList::SHOPPING_LIST_SORTING_ORDERS
    valid_sorting_orders.each do |valid_order|
      @user_one.sorting_order = valid_order
      assert @user_one.valid?, "#{valid_order.inspect} should be valid"
      @user_two.sorting_order = valid_order
      assert @user_two.valid?, "#{valid_order.inspect} should be valid"
    end
  end

  test "sorting_order should reject invalid values" do
    invalid_sorting_orders = %w[ascending descending random nil_value]
    invalid_sorting_orders.each do |invalid_order|
      @user_one.sorting_order = invalid_order
      assert_not @user_one.valid?, "#{invalid_order.inspect} should be invalid"
    end
  end

  test "sorting_order should allow nil" do
    @user_one.sorting_order = nil
    assert @user_one.valid?
  end

  test "is_new_user? should return true for new users" do
    new_user = User.create!(app_hash: "new_user_hash")
    assert new_user.is_new_user?
  end
end
