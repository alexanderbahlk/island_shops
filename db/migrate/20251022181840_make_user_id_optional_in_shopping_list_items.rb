class MakeUserIdOptionalInShoppingListItems < ActiveRecord::Migration[7.1]
  def change
    change_column_null :shopping_list_items, :user_id, true
  end
end
