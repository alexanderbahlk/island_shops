# == Schema Information
#
# Table name: shop_item_sub_category_types
#
#  id                        :bigint           not null, primary key
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  shop_item_sub_category_id :bigint           not null
#  shop_item_type_id         :bigint           not null
#
# Indexes
#
#  idx_on_shop_item_sub_category_id_7ec89870ff              (shop_item_sub_category_id)
#  index_shop_item_sub_category_types_on_shop_item_type_id  (shop_item_type_id)
#  index_sub_category_types_unique                          (shop_item_sub_category_id,shop_item_type_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (shop_item_sub_category_id => shop_item_sub_categories.id)
#  fk_rails_...  (shop_item_type_id => shop_item_types.id)
#
class ShopItemSubCategoryType < ApplicationRecord
  belongs_to :shop_item_sub_category
  belongs_to :shop_item_type

  validates :shop_item_sub_category_id, uniqueness: { scope: :shop_item_type_id }

  # Optional: add any additional attributes or methods for the relationship
  # For example, if you want to track when this relationship was created
  scope :recent, -> { order(created_at: :desc) }

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "shop_item_sub_category_id", "shop_item_type_id", "updated_at"]
  end
end
