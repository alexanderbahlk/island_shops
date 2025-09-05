class CreateShopItemTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :shop_item_types do |t|
      t.string :title, null: false

      t.timestamps
    end

    add_index :shop_item_types, :title

    create_table :shop_item_sub_category_types do |t|
      t.references :shop_item_sub_category, null: false, foreign_key: true
      t.references :shop_item_type, null: false, foreign_key: true

      t.timestamps
    end

    add_index :shop_item_sub_category_types,
              [:shop_item_sub_category_id, :shop_item_type_id],
              unique: true,
              name: "index_sub_category_types_unique"
  end
end
