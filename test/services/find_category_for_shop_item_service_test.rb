require 'test_helper'

class FindCategoryForShopItemServiceTest < ActiveSupport::TestCase
  include TitleNormalizer

  def setup
    @place = places(:place_one)
  end

  test 'should match organic milk category' do
    approvedOrganicMilkShopItem = shop_items(:shop_item_one)
    newOrganicMilkShopItem = ShopItem.new(title: 'Organicly made milk 1l', url: 'www.example.com',
                                          breadcrumb: 'PriceSmart > Groceries > Dairy and Eggs', place: @place)
    result = FindCategoryForShopItemService.new(shop_item: newOrganicMilkShopItem).find

    assert_equal approvedOrganicMilkShopItem.category, result
    assert_equal 0.6, result.sim_score
  end
end
