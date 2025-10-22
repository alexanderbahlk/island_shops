class AddUserToShopItems < ActiveRecord::Migration[7.1]
  def change
    # Add the user_id column to shop_items
    add_reference :shop_items, :user, foreign_key: { to_table: :users, on_delete: :nullify }, index: true
  end
end
