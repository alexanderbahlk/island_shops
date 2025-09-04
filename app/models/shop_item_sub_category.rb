class ShopItemSubCategory < ApplicationRecord
  belongs_to :shop_item_category

  validates :title, presence: true
  validates :title, uniqueness: { scope: :shop_item_category_id }

  def self.ransackable_associations(auth_object = nil)
    ["shop_item_category"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "shop_item_category_id", "title", "updated_at"]
  end
end
