# == Schema Information
#
# Table name: shopping_lists
#
#  id           :bigint           not null, primary key
#  deleted_at   :datetime
#  display_name :string           not null
#  slug         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_shopping_lists_on_deleted_at  (deleted_at)
#  index_shopping_lists_on_slug        (slug) UNIQUE
#
class ShoppingList < ApplicationRecord
  acts_as_paranoid

  include CategoryBreadcrumbHelper
  has_many :shopping_list_users, dependent: :destroy
  has_many :users, through: :shopping_list_users

  has_many :shopping_list_items, dependent: :destroy

  validates :slug, presence: true, uniqueness: true
  validates :display_name, presence: true, length: { minimum: 3 }

  before_validation :slugify, on: :create

  before_destroy :clear_active_shopping_list_references

  SHOPPING_LIST_GROUP_BY_ORDER_PRIORITY = "priority".freeze
  SHOPPING_LIST_GROUP_BY_ORDER_LOCATION = "location".freeze
  SHOPPING_LIST_GROUP_BY_ORDERS = [SHOPPING_LIST_GROUP_BY_ORDER_PRIORITY, SHOPPING_LIST_GROUP_BY_ORDER_LOCATION].freeze

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "display_name", "id", "id_value", "slug", "updated_at"]
  end

  def slugify
    self.slug = generate_slug
  end

  ## Returns the shopping list items formatted for the view list
  ## If group_shopping_lists_items_by is provided, it will group the items accordingly
  ## Possible values for group_shopping_lists_items_by are defined in SHOPPING_LIST_GROUP_BY_ORDERS
  ## Returns an array of arrays (purchased, unpurchased, priority, non-priority, location groups)
  def shopping_list_items_for_view_list(group_shopping_lists_items_by = nil)
    list = self.shopping_list_items.includes(:category).map do |item|
      {
        uuid: item.uuid,
        category_uuid: item.category&.uuid,
        shop_item_uuid: item.shop_item&.uuid,
        location_name: item.shop_item&.location&.title || "N/A",
        shop_item_count: item.category&.approved_cached_shop_items_count || 0,
        title: item.title_for_shopping_list_grouping(group_shopping_lists_items_by),
        purchased: item.purchased,
        quantity: item.quantity,
        priority: item.priority,
        breadcrumb: item.category.present? ? build_breadcrumb(item.category) : [],
      }
    end

    case group_shopping_lists_items_by
    when nil
      # Split into unpurchased and purchased groups
      {
        unpurchased: list.reject { |item| item[:purchased] }.sort_by { |item| item[:title] },
        purchased: list.select { |item| item[:purchased] }.sort_by { |item| item[:title] },
      }
    when ShoppingList::SHOPPING_LIST_GROUP_BY_ORDER_PRIORITY
      # Split into priority, non-priority, and purchased groups
      {
        priority: list.select { |item| item[:priority] && !item[:purchased] }.sort_by { |item| item[:title] },
        non_priority: list.reject { |item| item[:priority] || item[:purchased] }.sort_by { |item| item[:title] },
        purchased: list.select { |item| item[:purchased] }.sort_by { |item| item[:title] },
      }
    when ShoppingList::SHOPPING_LIST_GROUP_BY_ORDER_LOCATION
      # Group by location and add purchased items at the end
      unpurchased_items_grouped = list.reject { |item| item[:purchased] }.group_by { |item| item[:location_name] }
      unpurchased_items_sorted = unpurchased_items_grouped.transform_values do |items|
        items.sort_by { |item| item[:title] }
      end

      # Merge the grouped locations into the main object
      unpurchased_items_sorted.merge(
        purchased: list.select { |item| item[:purchased] }.sort_by { |item| item[:title] },
      )
    end
  end

  private

  def clear_active_shopping_list_references
    User.where(active_shopping_list_id: self.id).update_all(active_shopping_list_id: nil)
  end

  #kill rails server: kill -9 10234

  def generate_slug
    loop do
      slug = SecureRandom.hex(4).upcase # Generates an 8-character slug
      return slug unless ShoppingList.exists?(slug: slug)
    end
  end
end
