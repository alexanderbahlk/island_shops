class CreateJoinTableUsersShoppingLists < ActiveRecord::Migration[7.1]
  def change
    create_table :shopping_list_users do |t|
      t.references :user, null: false, foreign_key: true
      t.references :shopping_list, null: false, foreign_key: true

      t.timestamps
    end

    add_index :shopping_list_users, [:user_id, :shopping_list_id], unique: true
  end
end
