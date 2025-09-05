# == Schema Information
#
# Table name: shop_item_types
#
#  id         :bigint           not null, primary key
#  title      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_shop_item_types_on_title  (title)
#
require "test_helper"

class ShopItemTypeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
