# == Schema Information
#
# Table name: shop_items
#
#  id                   :bigint           not null, primary key
#  approved             :boolean          default(FALSE)
#  display_title        :string
#  image_url            :string
#  location             :string
#  needs_another_review :boolean          default(FALSE)
#  shop                 :string           not null
#  size                 :decimal(10, 2)
#  title                :string           not null
#  unit                 :string
#  url                  :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  product_id           :string
#  shop_item_type_id    :bigint
#
# Indexes
#
#  index_shop_items_on_shop_item_type_id  (shop_item_type_id)
#  index_shop_items_on_url                (url) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (shop_item_type_id => shop_item_types.id)
#
require "test_helper"

class ShopItemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
