class RemoveLocationFromShopItem < ActiveRecord::Migration[7.1]
  def change
    remove_column :shop_items, :location, :string
  end
end
