class EnablePgTrgm < ActiveRecord::Migration[7.1]
  def up
    # Enable the pg_trgm extension
    enable_extension "pg_trgm"

    # Remove the existing regular index first
    if index_exists?(:shop_item_types, :title)
      remove_index :shop_item_types, :title
    end

    # Add GIN index for trigram matching on shop_item_types.title
    add_index :shop_item_types, :title, using: :gin, opclass: :gin_trgm_ops
  end

  def down
    # Remove the GIN index
    if index_exists?(:shop_item_types, :title)
      remove_index :shop_item_types, :title
    end

    # Add back the regular index
    add_index :shop_item_types, :title

    # Disable the extension
    disable_extension "pg_trgm"
  end
end
