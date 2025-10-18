class AddDeletedAtToShoppingList < ActiveRecord::Migration[7.1]
  def change
    add_column :shopping_lists, :deleted_at, :datetime
    add_index :shopping_lists, :deleted_at
  end
end
