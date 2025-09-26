class AddQuantityToShoppingListItems < ActiveRecord::Migration[7.1]
  def change
    add_column :shopping_list_items, :quantity, :integer, default: 1, null: false
  end
end
