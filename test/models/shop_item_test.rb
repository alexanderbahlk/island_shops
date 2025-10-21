# == Schema Information
#
# Table name: shop_items
#
#  id                           :bigint           not null, primary key
#  approved                     :boolean          default(FALSE)
#  breadcrumb                   :string
#  display_title                :string
#  image_url                    :string
#  model_embedding              :jsonb
#  needs_another_review         :boolean          default(FALSE)
#  needs_model_embedding_update :boolean          default(FALSE), not null
#  size                         :decimal(10, 2)
#  title                        :string           not null
#  unit                         :string
#  url                          :string           not null
#  uuid                         :uuid             not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  category_id                  :bigint
#  place_id                     :bigint
#  product_id                   :string
#
# Indexes
#
#  index_shop_items_on_breadcrumb       (breadcrumb)
#  index_shop_items_on_category_id      (category_id)
#  index_shop_items_on_model_embedding  (model_embedding) USING gin
#  index_shop_items_on_place_id         (place_id)
#  index_shop_items_on_url              (url) UNIQUE
#  index_shop_items_on_uuid             (uuid) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (place_id => places.id)
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
end
