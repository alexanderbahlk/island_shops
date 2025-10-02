class RemoveShopFromShopItem < ActiveRecord::Migration[7.1]
  def change
    remove_column :shop_items, :shop, :string
  end
end
