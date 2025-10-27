class AddShopItemStockStatusFilterToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :shop_item_stock_status_filter, :string, default: "all", null: false
  end
end
