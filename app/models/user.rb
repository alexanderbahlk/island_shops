# == Schema Information
#
# Table name: users
#
#  id         :bigint           not null, primary key
#  app_hash   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class User < ApplicationRecord
  has_many :shopping_lists, dependent: :destroy
  has_many :shopping_list_items, dependent: :destroy

  validates :app_hash, presence: true, uniqueness: true

  validates :sorting_order, inclusion: { in: ShoppingList::SHOPPING_LIST_SORTING_ORDERS, allow_nil: true }

  def self.ransackable_attributes(auth_object = nil)
    ["app_hash", "created_at", "id", "id_value", "updated_at"]
  end

  def is_new_user?
    shopping_lists.count == 0
  end
end
