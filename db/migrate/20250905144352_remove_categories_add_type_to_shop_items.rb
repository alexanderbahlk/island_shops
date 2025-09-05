class RemoveCategoriesAddTypeToShopItems < ActiveRecord::Migration[7.1]
  def up
    # Remove foreign key constraints first (only if they exist)
    if foreign_key_exists?(:shop_items, :shop_item_categories)
      remove_foreign_key :shop_items, :shop_item_categories
    end

    if foreign_key_exists?(:shop_items, :shop_item_sub_categories)
      remove_foreign_key :shop_items, :shop_item_sub_categories
    end

    # Remove the columns (only if they exist)
    if column_exists?(:shop_items, :shop_item_category_id)
      remove_column :shop_items, :shop_item_category_id, :bigint
    end

    if column_exists?(:shop_items, :shop_item_sub_category_id)
      remove_column :shop_items, :shop_item_sub_category_id, :bigint
    end

    # Add the new shop_item_type reference (only if it doesn't exist)
    unless column_exists?(:shop_items, :shop_item_type_id)
      add_reference :shop_items, :shop_item_type, null: true, foreign_key: true
    end

    # Add index only if it doesn't exist
    unless index_exists?(:shop_items, :shop_item_type_id)
      add_index :shop_items, :shop_item_type_id
    end

    # Add foreign key if column exists but foreign key doesn't
    if column_exists?(:shop_items, :shop_item_type_id) && !foreign_key_exists?(:shop_items, :shop_item_types)
      add_foreign_key :shop_items, :shop_item_types
    end
  end

  def down
    # Remove the shop_item_type reference (only if it exists)
    if foreign_key_exists?(:shop_items, :shop_item_types)
      remove_foreign_key :shop_items, :shop_item_types
    end

    if index_exists?(:shop_items, :shop_item_type_id)
      remove_index :shop_items, :shop_item_type_id
    end

    if column_exists?(:shop_items, :shop_item_type_id)
      remove_column :shop_items, :shop_item_type_id, :bigint
    end

    # Add back the category columns (only if they don't exist)
    unless column_exists?(:shop_items, :shop_item_category_id)
      add_reference :shop_items, :shop_item_category, null: true, foreign_key: true
    end

    unless column_exists?(:shop_items, :shop_item_sub_category_id)
      add_reference :shop_items, :shop_item_sub_category, null: true, foreign_key: true
    end

    # Add indexes if they don't exist
    unless index_exists?(:shop_items, :shop_item_category_id)
      add_index :shop_items, :shop_item_category_id
    end

    unless index_exists?(:shop_items, :shop_item_sub_category_id)
      add_index :shop_items, :shop_item_sub_category_id
    end
  end
end
