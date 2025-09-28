class AddPriorityToShoppingListItems < ActiveRecord::Migration[7.1]
  def change
    add_column :shopping_list_items, :priority, :boolean, default: false, null: false
  end
end
