# == Schema Information
#
# Table name: shopping_lists
#
#  id           :bigint           not null, primary key
#  display_name :string           not null
#  slug         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_shopping_lists_on_slug     (slug) UNIQUE
#  index_shopping_lists_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class ShoppingListTest < ActiveSupport::TestCase
  def setup
    @user = users(:user_one) # Assuming a fixture exists
    @shopping_list = ShoppingList.new(
      display_name: "Weekly Groceries",
      user: @user,
    )
    @shopping_list.users << @user
    @shopping_list_with_items = shopping_lists(:shopping_list_abc) # Assuming a fixture exists
  end

  test "shopping_list_items_for_view_list returns items sorted by title" do
    result = @shopping_list_with_items.shopping_list_items_for_view_list

    # Ensure the result is sorted by title
    assert_equal ["Cheese", "Milk 2x", "Goat Cheese"], result.map { |item| item[:title] }
  end

  test "shopping_list_items_for_view_list includes uuid, title, and purchased fields" do
    result = @shopping_list_with_items.shopping_list_items_for_view_list

    # Ensure each item includes the required fields
    result.each do |item|
      assert item.key?(:uuid), "Item is missing uuid"
      assert item.key?(:title), "Item is missing title"
      assert item.key?(:purchased), "Item is missing purchased"
    end
  end

  test "shopping_list_items_for_view_list generates correct breadcrumbs" do
    result = @shopping_list_with_items.shopping_list_items_for_view_list

    # Ensure breadcrumbs are generated correctly
    milk_item = result.find { |item| item[:title] == "Milk 2x" }
    cheese_item = result.find { |item| item[:title] == "Cheese" }

    assert_equal ["Food", "Fresh Food", "Dairy"], milk_item[:breadcrumb], "Breadcrumb for Milk is incorrect"
    assert_equal ["Food", "Fresh Food", "Dairy"], cheese_item[:breadcrumb], "Breadcrumb for Cheese is incorrect"
  end

  test "shopping_list_items_for_view_list handles empty shopping list" do
    empty_list = ShoppingList.create!(display_name: "Empty List", user: @user)
    result = empty_list.shopping_list_items_for_view_list

    # Ensure the result is an empty array
    assert_equal [], result
  end

  test "should respond to attributes" do
    assert_respond_to @shopping_list, :display_name
    assert_respond_to @shopping_list, :slug
  end

  test "should create a new shopping list with only display_name" do
    shopping_list = ShoppingList.new(display_name: "New List", user: @user)
    shopping_list.users << @user
    assert shopping_list.valid?, "Validation failed: #{shopping_list.errors.full_messages}"

    assert shopping_list.save
  end

  # Test validations
  test "should be valid with valid attributes" do
    assert @shopping_list.valid?
  end

  test "should require a display_name" do
    @shopping_list.display_name = nil
    assert_not @shopping_list.valid?
    assert_includes @shopping_list.errors[:display_name], "can't be blank"
  end

  test "should require a display_name with minimum length" do
    @shopping_list.display_name = "AB"
    assert_not @shopping_list.valid?
    assert_includes @shopping_list.errors[:display_name], "is too short (minimum is 3 characters)"
  end

  test "should require a unique slug" do
    @shopping_list.save!
    duplicate_list = @shopping_list.dup
    duplicate_list.slug = @shopping_list.slug
    assert duplicate_list.valid?, "Validation failed: #{duplicate_list.errors.full_messages}"
    assert_not_equal duplicate_list.slug, @shopping_list.slug
  end

  # Test slug generation
  test "should generate a unique slug on creation" do
    @shopping_list.save!
    assert_not_nil @shopping_list.slug
    assert_equal 8, @shopping_list.slug.length
  end

  test "should generate a different slug for each shopping list" do
    @shopping_list.save!
    another_list = ShoppingList.create!(
      display_name: "Another List",
      user: @user,
    )
    assert_not_equal @shopping_list.slug, another_list.slug
  end
end
