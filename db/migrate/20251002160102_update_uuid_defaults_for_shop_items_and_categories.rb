class UpdateUuidDefaultsForShopItemsAndCategories < ActiveRecord::Migration[7.1]
  def change
    # Update uuid column in shop_items
    change_column :shop_items, :uuid, :uuid, default: -> { "gen_random_uuid()" }, null: false
    add_index :shop_items, :uuid, unique: true

    # Update uuid column in categories
    change_column :categories, :uuid, :uuid, default: -> { "gen_random_uuid()" }, null: false
    add_index :categories, :uuid, unique: true
  end
end
