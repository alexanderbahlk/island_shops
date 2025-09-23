class UpdateShoppingListItems < ActiveRecord::Migration[7.1]
  def change
    # Remove the two indexes
    remove_index :shopping_list_items, name: "index_shopping_list_items_on_shopping_list_id"
    remove_index :shopping_list_items, name: "index_shopping_list_items_on_category_id"

    # Add a uuid column
    add_column :shopping_list_items, :uuid, :uuid, null: false, default: -> { "gen_random_uuid()" }

    # Add a unique index on the uuid column
    add_index :shopping_list_items, :uuid, unique: true
  end
end
