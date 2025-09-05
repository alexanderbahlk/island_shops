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
#  index_shop_item_types_on_title  (title) USING gin
#
class ShopItemType < ApplicationRecord
  has_many :shop_item_sub_category_types, dependent: :destroy
  has_many :shop_item_sub_categories, through: :shop_item_sub_category_types
  has_many :shop_items, dependent: :nullify

  validates :title, presence: true, uniqueness: true

  # Find similar types using trigram matching
  def self.find_similar(title, threshold: 0.3, limit: 5)
    return none if title.blank?

    select("*, similarity(title, ?) as sim_score")
      .where("similarity(title, ?) > ?", title, threshold)
      .order("sim_score DESC")
      .limit(limit)
  end

  # Helper method to check if this type belongs to a specific subcategory
  def belongs_to_subcategory?(subcategory)
    shop_item_sub_categories.include?(subcategory)
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "title", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["shop_item_sub_categories", "shop_item_sub_category_types", "shop_items"]
  end
end
