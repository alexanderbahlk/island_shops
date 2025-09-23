class AddDisplayNameToShoppingLists < ActiveRecord::Migration[7.1]
  def change
    add_column :shopping_lists, :display_name, :string, null: false
  end
end
