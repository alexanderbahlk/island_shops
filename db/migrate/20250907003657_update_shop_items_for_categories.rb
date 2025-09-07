class UpdateShopItemsForCategories < ActiveRecord::Migration[7.0]
  def up
    # Add the new category reference
    add_reference :shop_items, :category, null: true, foreign_key: { to_table: :categories }

    # Remove the old shop_item_type_id reference
    remove_foreign_key :shop_items, :shop_item_types if foreign_key_exists?(:shop_items, :shop_item_types)
    remove_index :shop_items, :shop_item_type_id if index_exists?(:shop_items, :shop_item_type_id)
    remove_column :shop_items, :shop_item_type_id, :bigint
  end

  def down
    # Reverse the changes

    add_reference :shop_items, :shop_item_type, null: true, foreign_key: true

    remove_index :shop_items, :category_id if index_exists?(:shop_items, :category_id)
    remove_foreign_key :shop_items, :categories if foreign_key_exists?(:shop_items, :categories)
    remove_column :shop_items, :category_id, :bigint
  end
end
