# == Schema Information
#
# Table name: users
#
#  id                            :bigint           not null, primary key
#  app_hash                      :string
#  group_shopping_lists_items_by :string
#  shop_item_stock_status_filter :string           default("all"), not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  active_shopping_list_id       :bigint
#
# Indexes
#
#  index_users_on_active_shopping_list_id  (active_shopping_list_id)
#
# Foreign Keys
#
#  fk_rails_...  (active_shopping_list_id => shopping_lists.id)
#
class User < ApplicationRecord
  has_many :shopping_list_users, dependent: :destroy
  has_many :shopping_lists, through: :shopping_list_users
  has_many :shop_items

  has_many :shopping_list_items, dependent: :destroy
  belongs_to :active_shopping_list, class_name: "ShoppingList", optional: true
  validate :active_shopping_list_belongs_to_user

  validates :app_hash, presence: true, uniqueness: true

  SHOP_ITEM_STOCK_STATUS_FILTERS = %w[all in_stock_only].freeze

  validates :group_shopping_lists_items_by, inclusion: { in: ShoppingList::SHOPPING_LIST_GROUP_BY_ORDERS, allow_nil: true }
  validates :shop_item_stock_status_filter, inclusion: { in: SHOP_ITEM_STOCK_STATUS_FILTERS }

  def self.ransackable_attributes(auth_object = nil)
    ["app_hash", "created_at", "id", "id_value", "updated_at"]
  end

  def is_new_user?
    shopping_lists.count == 0
  end

  def filter_shop_items_by_stock_status?
    shop_item_stock_status_filter == "in_stock_only"
  end

  private

  def active_shopping_list_belongs_to_user
    if active_shopping_list && !shopping_lists.include?(active_shopping_list)
      errors.add(:active_shopping_list, "must belong to the user")
    end
  end
end
