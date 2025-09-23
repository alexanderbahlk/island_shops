class RemoveProductsTempFromShoppingLists < ActiveRecord::Migration[7.1]
  def change
    remove_column :shopping_lists, :products_temp, :jsonb
  end
end
