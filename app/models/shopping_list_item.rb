# == Schema Information
#
# Table name: shopping_list_items
#
#  id               :bigint           not null, primary key
#  purchased        :boolean          default(FALSE), not null
#  title            :string           not null
#  uuid             :uuid             not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  category_id      :bigint
#  shopping_list_id :bigint           not null
#
# Indexes
#
#  index_shopping_list_items_on_category_id  (category_id)
#  index_shopping_list_items_on_uuid         (uuid) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (shopping_list_id => shopping_lists.id)
#
class ShoppingListItem < ApplicationRecord
  belongs_to :shopping_list
  belongs_to :category, optional: true

  validates :category, presence: true, if: -> { category_id.present? }
  validate :category_must_be_product, if: -> { category.present? }

  validates :title, presence: true
  before_validation :set_title_from_category, if: -> { category.present? }, on: :create

  private

  def category_must_be_product
    unless category.product?
      errors.add(:category, "must be a product category")
    end
  end

  # Set the title from the category's title if it exists and title is blank
  def set_title_from_category
    self.title = category.title
  end
end
