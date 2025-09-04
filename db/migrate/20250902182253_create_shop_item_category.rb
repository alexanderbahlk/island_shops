class CreateShopItemCategory < ActiveRecord::Migration[7.1]
  def change
    create_table :shop_item_categories do |t|
      t.string :title, null: false

      t.timestamps
    end

    add_index :shop_item_categories, :title

    create_table :shop_item_sub_categories do |t|
      t.string :title, null: false
      t.references :shop_item_category, null: false, foreign_key: true

      t.timestamps
    end

    add_index :shop_item_sub_categories, :title
    add_index :shop_item_sub_categories, [:shop_item_category_id, :title], unique: true
  end
end
