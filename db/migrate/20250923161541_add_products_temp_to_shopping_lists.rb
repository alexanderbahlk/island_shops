class AddProductsTempToShoppingLists < ActiveRecord::Migration[7.1]
  def change
    change_column_default :shopping_lists, :products_temp, []
  end
end
