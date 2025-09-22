# == Schema Information
#
# Table name: shopping_lists
#
#  id            :bigint           not null, primary key
#  products_temp :jsonb
#  slug          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_shopping_lists_on_slug  (slug) UNIQUE
#
class ShoppingList < ApplicationRecord
  has_and_belongs_to_many :categories, -> { where(category_type: :product) }, class_name: "Category"

  validates :slug, presence: true, uniqueness: true
  validates :products_temp, presence: true

  before_validation :generate_slug, on: :create

  private

  def generate_slug
    self.slug ||= loop do
      random_slug = SecureRandom.alphanumeric(8).upcase
      break random_slug unless self.class.exists?(slug: random_slug)
    end
  end
end
