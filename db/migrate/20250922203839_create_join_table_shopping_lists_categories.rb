# filepath: db/migrate/XXXXXXXXXXXXXX_create_join_table_shopping_lists_categories.rb
class CreateJoinTableShoppingListsCategories < ActiveRecord::Migration[7.0]
  def change
    create_join_table :shopping_lists, :categories do |t|
      t.index [:shopping_list_id, :category_id], unique: true, name: "index_shopping_lists_categories_on_list_and_category"
      t.index [:category_id, :shopping_list_id], name: "index_shopping_lists_categories_on_category_and_list"
    end
  end
end
