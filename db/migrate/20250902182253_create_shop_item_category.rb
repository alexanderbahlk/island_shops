class CreateShopItemCategory < ActiveRecord::Migration[7.1]
  def change
    create_table :shop_item_categories do |t|
      t.string :title, null: false

      t.timestamps
    end

    add_index :shop_item_categories, :title
  end
end
