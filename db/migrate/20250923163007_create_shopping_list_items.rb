class CreateShoppingListItems < ActiveRecord::Migration[7.1]
  def change
    create_table :shopping_list_items do |t|
      t.string :title, null: false
      t.references :category, foreign_key: true, null: true
      t.references :shopping_list, foreign_key: true, null: false

      t.timestamps
    end
  end
end
