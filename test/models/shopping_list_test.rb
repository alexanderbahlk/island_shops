# == Schema Information
#
# Table name: shopping_lists
#
#  id           :bigint           not null, primary key
#  display_name :string           not null
#  slug         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_shopping_lists_on_slug  (slug) UNIQUE
#
require "test_helper"

class ShoppingListTest < ActiveSupport::TestCase
  def setup
    @shopping_list = ShoppingList.new(
      display_name: "Weekly Groceries",
    )
  end

  test "should respond to attributes" do
    assert_respond_to @shopping_list, :display_name
    assert_respond_to @shopping_list, :slug
  end

  test "should create a new shopping list with only display_name" do
    shopping_list = ShoppingList.new(display_name: "New List")
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
    )
    assert_not_equal @shopping_list.slug, another_list.slug
  end
end
