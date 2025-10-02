# == Schema Information
#
# Table name: categories
#
#  id            :bigint           not null, primary key
#  category_type :integer          default("root"), not null
#  depth         :integer          default(0)
#  lft           :integer          not null
#  path          :string
#  rgt           :integer          not null
#  slug          :string           not null
#  sort_order    :integer          default(0)
#  synonyms      :text             default([]), is an Array
#  title         :string           not null
#  uuid          :uuid             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  parent_id     :bigint
#
# Indexes
#
#  index_categories_on_category_type             (category_type)
#  index_categories_on_lft_and_rgt               (lft,rgt)
#  index_categories_on_parent_id                 (parent_id)
#  index_categories_on_parent_id_and_slug        (parent_id,slug) UNIQUE
#  index_categories_on_parent_id_and_sort_order  (parent_id,sort_order)
#  index_categories_on_path                      (path)
#  index_categories_on_uuid                      (uuid) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (parent_id => categories.id)
#
require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  def setup
    @root_category = categories(:food_root)
    @category = categories(:fresh_food)
    @subcategory = categories(:dairy)
    @product_category = categories(:milk)

    @shop_item1 = shop_items(:shop_item_one)
    @shop_item2 = shop_items(:shop_item_four)
  end

  test "clears direct references and marks items as unapproved when deleting category" do
    assert_difference "ShopItem.where(category_id: #{@product_category.id}).count", -2 do
      @product_category.destroy!
    end

    @shop_item1.reload
    @shop_item2.reload

    assert_nil @shop_item1.category_id
    assert_not @shop_item1.approved
    assert_nil @shop_item2.category_id
    assert_not @shop_item2.approved
  end

  test "should update subcategory and paths of children when parent title changes" do
    old_path = @subcategory.path
    @category.update!(title: "Updated Fresh Food")
    @subcategory.reload
    assert_not_equal old_path, @subcategory.path
    assert_equal "food/updated-fresh-food/dairy", @subcategory.path
  end

  test "clears all nested references when deleting root category" do
    total_items = ShopItem.joins(:category)
      .where(categories: { id: @root_category.self_and_descendants.pluck(:id) })
      .count
    assert_equal 3, total_items

    assert_difference "ShopItem.where.not(category_id: nil).count", -3 do
      @root_category.destroy!
    end
  end

  test "does not raise foreign key violation errors" do
    assert_nothing_raised do
      @product_category.destroy!
    end
  end

  test "handles destruction in transaction with rollback" do
    assert_no_difference ["ShopItem.count", "Category.count"] do
      ActiveRecord::Base.transaction do
        @subcategory.destroy!
        raise ActiveRecord::Rollback
      end
    end
  end

  test "destroys children categories" do
    assert_equal @subcategory.parent, @category
    assert_equal 4, @subcategory.children.count
    assert_difference "Category.count", -5 do # subcategory + 2 products
      @subcategory.destroy!
    end
    assert_not Category.exists?(@subcategory.id)
    assert Category.exists?(@category.id)
  end

  test "nullifies shop item references instead of destroying them" do
    assert_no_difference "ShopItem.count" do
      @product_category.destroy!
    end

    category_ids = ShopItem.where(id: [@shop_item1.id, @shop_item2.id]).pluck(:category_id)
    assert category_ids.all?(&:nil?)
  end

  test "should have uuid present and unique" do
    category = Category.create!(title: "New Category", parent: @root_category)
    assert category.uuid.present?
    assert category.valid?

    duplicate = Category.new(title: "Duplicate Category", parent: @root_category, uuid: category.uuid)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:uuid], "has already been taken"
  end
end
