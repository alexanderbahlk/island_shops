class AddPurchasedToShoppingListItems < ActiveRecord::Migration[7.1]
  def change
    add_column :shopping_list_items, :purchased, :boolean, default: false, null: false
  end
end
