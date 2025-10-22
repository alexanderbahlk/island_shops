class UpdateUserForeignKeyOnShoppingListItems < ActiveRecord::Migration[7.1]
  def change
    # Remove the existing foreign key
    remove_foreign_key :shopping_list_items, :users

    # Add a new foreign key with ON DELETE SET NULL
    add_foreign_key :shopping_list_items, :users, column: :user_id, on_delete: :nullify
  end
end
