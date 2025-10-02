class AddShopItemToShoppingListItem < ActiveRecord::Migration[7.1]
  def change
    add_reference :shopping_list_items, :shop_item, foreign_key: true
  end
end
