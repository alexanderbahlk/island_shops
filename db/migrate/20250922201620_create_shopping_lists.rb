class CreateShoppingLists < ActiveRecord::Migration[7.0]
  def change
    create_table :shopping_lists do |t|
      t.string :slug, null: false, unique: true
      t.jsonb :products_temp, default: []

      t.timestamps
    end

    add_index :shopping_lists, :slug, unique: true
  end
end
