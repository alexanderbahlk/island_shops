class DropOldShopItemTables < ActiveRecord::Migration[7.1]
  def up
    # Drop tables in reverse order of dependencies to avoid foreign key constraints
    drop_table :shop_item_sub_category_types, if_exists: true
    drop_table :shop_item_sub_categories, if_exists: true
    drop_table :shop_item_categories, if_exists: true
    drop_table :shop_item_types, if_exists: true
  end

  def down
    # Recreate the tables in case we need to rollback
    # Note: This won't restore the data, only the structure

    create_table :shop_item_types do |t|
      t.string :title, null: false
      t.timestamps

      t.index :title, using: :gin, opclass: :gin_trgm_ops
    end

    create_table :shop_item_categories do |t|
      t.string :title, null: false
      t.timestamps

      t.index :title
    end

    create_table :shop_item_sub_categories do |t|
      t.string :title, null: false
      t.bigint :shop_item_category_id, null: false
      t.timestamps

      t.index :shop_item_category_id
      t.index :title
      t.index [:shop_item_category_id, :title], unique: true, name: "idx_on_shop_item_category_id_title_46d450a20d"
    end

    create_table :shop_item_sub_category_types do |t|
      t.bigint :shop_item_sub_category_id, null: false
      t.bigint :shop_item_type_id, null: false
      t.timestamps

      t.index :shop_item_sub_category_id, name: "idx_on_shop_item_sub_category_id_7ec89870ff"
      t.index :shop_item_type_id
      t.index [:shop_item_sub_category_id, :shop_item_type_id], unique: true, name: "index_sub_category_types_unique"
    end

    # Add foreign keys
    add_foreign_key :shop_item_sub_categories, :shop_item_categories
    add_foreign_key :shop_item_sub_category_types, :shop_item_sub_categories
    add_foreign_key :shop_item_sub_category_types, :shop_item_types
  end
end
