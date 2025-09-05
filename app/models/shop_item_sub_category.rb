# == Schema Information
#
# Table name: shop_item_sub_categories
#
#  id                    :bigint           not null, primary key
#  title                 :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  shop_item_category_id :bigint           not null
#
# Indexes
#
#  idx_on_shop_item_category_id_title_46d450a20d            (shop_item_category_id,title) UNIQUE
#  index_shop_item_sub_categories_on_shop_item_category_id  (shop_item_category_id)
#  index_shop_item_sub_categories_on_title                  (title)
#
# Foreign Keys
#
#  fk_rails_...  (shop_item_category_id => shop_item_categories.id)
#
class ShopItemSubCategory < ApplicationRecord
  belongs_to :shop_item_category
  has_many :shop_item_sub_category_types, dependent: :destroy
  has_many :shop_item_types, through: :shop_item_sub_category_types

  validates :title, presence: true, uniqueness: true

  # Helper method to add a type to this subcategory
  def add_type(type_title)
    type = ShopItemType.find_or_create_by!(title: type_title)
    shop_item_types << type unless shop_item_types.include?(type)
    type
  end

  def self.ransackable_associations(auth_object = nil)
    ["shop_item_category", "shop_item_sub_category_types", "shop_item_types"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "shop_item_category_id", "title", "updated_at"]
  end
end
