class CreateShopItems < ActiveRecord::Migration[7.1]
  def change
    create_table :shop_items do |t|
      t.string :url
      t.string :title
      t.string :image_url
      t.string :size
      t.string :location
      t.string :product_id

      t.timestamps
    end
    add_index :shop_items, :url, unique: true
  end
end
