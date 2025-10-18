class AddDeletedAtToShoppingListItem < ActiveRecord::Migration[7.1]
  def change
    add_column :shopping_list_items, :deleted_at, :datetime
    add_index :shopping_list_items, :deleted_at
  end
end
