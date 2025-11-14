class AddCategoryForeignKeyToShoppingListItems < ActiveRecord::Migration[7.1]
  def change
    unless foreign_key_exists?(:shopping_list_items, :categories)
      add_foreign_key :shopping_list_items, :categories
    end
  end
end
