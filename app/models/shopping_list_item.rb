# == Schema Information
#
# Table name: shopping_list_items
#
#  id               :bigint           not null, primary key
#  deleted_at       :datetime
#  priority         :boolean          default(FALSE), not null
#  purchased        :boolean          default(FALSE), not null
#  quantity         :integer          default(1), not null
#  title            :string           not null
#  uuid             :uuid             not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  category_id      :bigint
#  shop_item_id     :bigint
#  shopping_list_id :bigint           not null
#  user_id          :bigint
#
# Indexes
#
#  index_shopping_list_items_on_category_id   (category_id)
#  index_shopping_list_items_on_deleted_at    (deleted_at)
#  index_shopping_list_items_on_shop_item_id  (shop_item_id)
#  index_shopping_list_items_on_user_id       (user_id)
#  index_shopping_list_items_on_uuid          (uuid) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (shop_item_id => shop_items.id)
#  fk_rails_...  (shopping_list_id => shopping_lists.id)
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
class ShoppingListItem < ApplicationRecord
  acts_as_paranoid
  #https://github.com/ActsAsParanoid/acts_as_paranoid

  belongs_to :shop_item, optional: true
  belongs_to :user, optional: true
  belongs_to :shopping_list
  belongs_to :category, optional: true

  validates :category, presence: true, if: -> { category_id.present? }
  validate :category_must_be_product, if: -> { category.present? }

  validates :title, presence: true
  validates :quantity, numericality: { greater_than: 0, only_integer: true }

  validates :uuid, uniqueness: true

  before_validation :set_title_from_category, if: -> { category.present? }, on: :create

  scope :without_category, -> { where(category_id: nil) }
  scope :purchased, -> { where(purchased: true) }
  scope :unbought, -> { where(purchased: false) }
  scope :priority, -> { where(priority: true) }
  scope :non_priority, -> { where(priority: false) }

  def self.ransackable_attributes(auth_object = nil)
    ["category_id", "created_at", "id", "id_value", "priority", "purchased", "quantity", "shopping_list_id", "title", "updated_at", "user_id", "uuid"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["category", "shopping_list", "user"]
  end

  def title_for_shopping_list_grouping(shopping_list_grouping = nil)
    title_string = title
    if quantity > 1
      title_string = "#{title_string} #{quantity}x"
    end
    case shopping_list_grouping
    when nil
    when ShoppingList::SHOPPING_LIST_GROUP_BY_ORDER_PRIORITY
      if shop_item_id
        if shop_item && shop_item.place.present?
          title_string += " from #{shop_item.place.title}"
        end
      end
    when ShoppingList::SHOPPING_LIST_GROUP_BY_ORDER_PLACE
      title_string
    end
    title_string
  end

  private

  def clear_shop_item_references
    User.where(active_shopping_list_id: self.id).update_all(active_shopping_list_id: nil)
  end

  def category_must_be_product
    unless category.product?
      errors.add(:category, "must be a product category")
    end
  end

  # Set the title from the category's title if it exists and title is blank
  def set_title_from_category
    self.title = category&.title
  end
end
