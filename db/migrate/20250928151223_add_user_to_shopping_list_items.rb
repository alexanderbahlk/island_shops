class AddUserToShoppingListItems < ActiveRecord::Migration[7.1]
  def change
    add_reference :shopping_list_items, :user, null: false, foreign_key: true
  end
end
