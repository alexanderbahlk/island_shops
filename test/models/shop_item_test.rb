# == Schema Information
#
# Table name: shop_items
#
#  id                   :bigint           not null, primary key
#  approved             :boolean          default(FALSE)
#  breadcrumb           :string
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
#  category_id          :bigint
#  product_id           :string
#
# Indexes
#
#  index_shop_items_on_breadcrumb   (breadcrumb)
#  index_shop_items_on_category_id  (category_id)
#  index_shop_items_on_url          (url) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#
require "test_helper"

class ShopItemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
