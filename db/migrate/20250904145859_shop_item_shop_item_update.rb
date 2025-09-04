class ShopItemShopItemUpdate < ActiveRecord::Migration[7.1]
  def change
    create_table :shop_items do |t|
      t.string :shop, null: false
      t.string :url, null: false
      t.string :title, null: false
      t.string :display_title
      t.string :image_url
      t.decimal :size, precision: 10, scale: 2
      t.string :unit
      t.string :location
      t.string :product_id
      t.boolean :approved, default: false
      t.boolean :needs_another_review, default: false

      t.timestamps
    end
    add_index :shop_items, :url, unique: true

    add_reference :shop_items, :shop_item_category, null: true, foreign_key: true
    add_reference :shop_items, :shop_item_sub_category, null: true, foreign_key: true

    create_table :shop_item_updates do |t|
      t.decimal :price, null: false, precision: 10, scale: 2
      t.decimal :price_per_unit, precision: 10, scale: 2
      t.string :stock_status
      t.references :shop_item, null: false, foreign_key: true

      t.timestamps
    end
  end
end
