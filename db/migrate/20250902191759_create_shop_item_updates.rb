class CreateShopItemUpdates < ActiveRecord::Migration[7.1]
  def change
    create_table :shop_item_updates do |t|
      t.decimal :price, null: false, precision: 10, scale: 2
      t.decimal :price_per_unit, precision: 10, scale: 2
      t.string :stock_status
      t.references :shop_item, null: false, foreign_key: true

      t.timestamps
    end
  end
end
