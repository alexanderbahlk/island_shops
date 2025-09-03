class CreateShopItems < ActiveRecord::Migration[7.1]
  def change
    create_table :shop_items do |t|
      t.string :shop, null: false
      t.string :url, null: false
      t.string :title, null: false
      t.string :display_title
      t.string :image_url
      t.string :size
      t.string :location
      t.string :product_id
      t.boolean :approved, default: false

      t.timestamps
    end
    add_index :shop_items, :url, unique: true
  end
end
