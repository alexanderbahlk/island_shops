class UpdateShoppingListItemsForCategories < ActiveRecord::Migration[7.1]
  def up
    # Add the new category reference with a foreign key and index
    #add_reference :shopping_list_items, :category, null: true, foreign_key: { to_table: :categories }

    # Add an index on category_id for better query performance
    add_index :shopping_list_items, :category_id
  end

  def down
    # Reverse the changes
    remove_index :shopping_list_items, :category_id if index_exists?(:shopping_list_items, :category_id)
    remove_foreign_key :shopping_list_items, :categories if foreign_key_exists?(:shopping_list_items, :categories)
    #remove_column :shopping_list_items, :category_id, :bigint
  end
end
