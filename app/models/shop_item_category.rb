class ShopItemCategory < ApplicationRecord
  has_many :shop_item_sub_categories, dependent: :destroy
  has_many :shop_items, dependent: :nullify

  validates :title, presence: true, uniqueness: true

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "title", "updated_at"]
  end
end
