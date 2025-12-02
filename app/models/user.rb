# == Schema Information
#
# Table name: users
#
#  id                            :bigint           not null, primary key
#  app_hash                      :string
#  device_data                   :jsonb
#  group_shopping_lists_items_by :string
#  last_activity_at              :datetime
#  shop_item_stock_status_filter :string           default("all"), not null
#  tutorial_step                 :integer          default(0), not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  active_shopping_list_id       :bigint
#
# Indexes
#
#  index_users_on_active_shopping_list_id  (active_shopping_list_id)
#  index_users_on_last_activity_at         (last_activity_at)
#
# Foreign Keys
#
#  fk_rails_...  (active_shopping_list_id => shopping_lists.id)
#
class User < ApplicationRecord
  has_many :shopping_list_users, dependent: :destroy
  has_many :shopping_lists, through: :shopping_list_users
  has_many :shop_items

  has_many :feedbacks, dependent: :destroy

  has_many :shopping_list_items, dependent: :destroy
  belongs_to :active_shopping_list, class_name: 'ShoppingList', optional: true
  validate :active_shopping_list_belongs_to_user

  validates :app_hash, presence: true, uniqueness: true

  SHOP_ITEM_STOCK_STATUS_FILTERS = %w[all in_stock_only].freeze

  validates :group_shopping_lists_items_by, inclusion: { in: ShoppingList::SHOPPING_LIST_GROUP_BY_ORDERS, allow_nil: true }
  validates :shop_item_stock_status_filter, inclusion: { in: SHOP_ITEM_STOCK_STATUS_FILTERS }

  validates :tutorial_step, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.ransackable_attributes(_auth_object = nil)
    %w[app_hash created_at id id_value updated_at]
  end

  def is_new_user?
    shopping_lists.count == 0
  end

  def filter_shop_items_by_stock_status?
    shop_item_stock_status_filter == 'in_stock_only'
  end

  def human_readable_device_data
    return {} unless device_data.is_a?(Hash)

    device_data.deep_transform_keys { |key| key.to_s.humanize }
  end

  private

  def active_shopping_list_belongs_to_user
    return unless active_shopping_list && !shopping_lists.include?(active_shopping_list)

    errors.add(:active_shopping_list, 'must belong to the user')
  end
end
