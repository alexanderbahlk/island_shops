class RemoveUserFromShoppingList < ActiveRecord::Migration[7.1]
  def change
    remove_reference :shopping_lists, :user, foreign_key: true, index: true
  end
end
