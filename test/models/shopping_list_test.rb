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
require "test_helper"

class ShoppingListTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
