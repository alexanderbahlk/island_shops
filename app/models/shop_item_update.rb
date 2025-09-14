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
class ShopItemUpdate < ApplicationRecord
  belongs_to :shop_item

  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :price_per_unit, presence: false, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  def normalized_stock_status
    case stock_status&.downcase
    when "in stock", "available", "yes", "true"
      "in stock"
    when "out of stock", "unavailable", "no", "false"
      "out of stock"
    when "limited", "few left", "low stock"
      "limited"
    else
      "N/A"
    end
  end

  def out_of_stock?
    normalized_stock_status == "out of stock"
  end
end
