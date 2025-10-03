class AddActiveShoppingListToUser < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :active_shopping_list, foreign_key: { to_table: :shopping_lists }
    rename_column :users, :sorting_order, :group_shopping_lists_items_by
  end
end
