# == Schema Information
#
# Table name: shop_items
#
#  id                   :bigint           not null, primary key
#  approved             :boolean          default(FALSE)
#  breadcrumb           :string
#  display_title        :string
#  image_url            :string
#  needs_another_review :boolean          default(FALSE)
#  size                 :decimal(10, 2)
#  title                :string           not null
#  unit                 :string
#  url                  :string           not null
#  uuid                 :uuid             not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  category_id          :bigint
#  place_id             :bigint
#  product_id           :string
#  user_id              :bigint
#
# Indexes
#
#  index_shop_items_on_approved     (approved)
#  index_shop_items_on_breadcrumb   (breadcrumb)
#  index_shop_items_on_category_id  (category_id)
#  index_shop_items_on_place_id     (place_id)
#  index_shop_items_on_url          (url) UNIQUE
#  index_shop_items_on_user_id      (user_id)
#  index_shop_items_on_uuid         (uuid) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (place_id => places.id)
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
require "test_helper"

class ShopItemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  #
  #
  test "should have uuid present and unique" do
    shop_item = ShopItem.create!(title: "New Item", url: "http://example.com/new-item")
    assert shop_item.uuid.present?
    assert shop_item.valid?

    duplicate = ShopItem.new(title: "Duplicate Item", url: "http://example.com/duplicate-item", uuid: shop_item.uuid)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:uuid], "has already been taken"
  end

  test "should delete shop_item without deleting associated shopping_list_items" do
    shop_item = shop_items(:shop_item_milk) # Assuming a fixture exists
    shopping_list_item = shopping_list_items(:shopping_list_item_milk) # Assuming a fixture exists
    shopping_list_item.update!(shop_item: shop_item)

    assert_difference("ShopItem.count", -1) do
      shop_item.destroy
    end

    shopping_list_item.reload
    assert_nil shopping_list_item.shop_item_id
  end

  test "should delete shop_item with associated user set to null" do
    user = users(:user_one) # Assuming a fixture exists
    shop_item = shop_items(:shop_item_with_user) # Assuming a fixture exists

    assert_difference("ShopItem.count", -1) do
      shop_item.destroy
    end

    assert User.exists?(user.id), "User should not be deleted when associated shop_item is destroyed"
  end
end
