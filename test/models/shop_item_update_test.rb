# == Schema Information
#
# Table name: shop_item_updates
#
#  id              :bigint           not null, primary key
#  normalized_unit :string
#  price           :decimal(10, 2)   not null
#  price_per_unit  :decimal(10, 2)
#  stock_status    :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  shop_item_id    :bigint           not null
#
# Indexes
#
#  index_shop_item_updates_on_shop_item_id  (shop_item_id)
#
# Foreign Keys
#
#  fk_rails_...  (shop_item_id => shop_items.id)
#
require "test_helper"

class ShopItemUpdateTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
