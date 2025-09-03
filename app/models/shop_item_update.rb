class ShopItemUpdate < ApplicationRecord
  belongs_to :shop_item

  validates :price, presence: true, numericality: { greater_than: 0 }
end
