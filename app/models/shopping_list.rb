# == Schema Information
#
# Table name: shopping_lists
#
#  id           :bigint           not null, primary key
#  display_name :string           not null
#  slug         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_shopping_lists_on_slug     (slug) UNIQUE
#  index_shopping_lists_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class ShoppingList < ApplicationRecord
  include CategoryBreadcrumbHelper
  belongs_to :user

  has_many :shopping_list_items, dependent: :destroy

  validates :slug, presence: true, uniqueness: true
  validates :display_name, presence: true, length: { minimum: 3 }

  before_validation :slugify, on: :create

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "display_name", "id", "id_value", "slug", "updated_at"]
  end

  def slugify
    self.slug = generate_slug
  end

  def shopping_list_items_for_view_list
    self.shopping_list_items.includes(:category).map do |item|
      {
        uuid: item.uuid,
        category_uuid: item.category&.uuid,
        shop_item_uuid: item.shop_item&.uuid,
        shop_name: item.shop_item&.shop,
        shop_item_count: item.category&.approved_cached_shop_items_count || 0,
        title: item.title_with_quantity_and_shop,
        purchased: item.purchased,
        quantity: item.quantity,
        priority: item.priority,
        breadcrumb: item.category.present? ? build_breadcrumb(item.category) : [],
      }
    end.sort_by { |item| [item[:purchased] ? 1 : 0, item[:priority] ? 0 : 1, item[:title]] }
  end

  private

  #kill rails server: kill -9 10234

  def generate_slug
    loop do
      slug = SecureRandom.hex(4).upcase # Generates an 8-character slug
      return slug unless ShoppingList.exists?(slug: slug)
    end
  end
end
