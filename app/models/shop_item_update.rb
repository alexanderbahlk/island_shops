class ShopItemUpdate < ApplicationRecord
  belongs_to :shop_item

  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :price_per_unit, presence: false, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
end
