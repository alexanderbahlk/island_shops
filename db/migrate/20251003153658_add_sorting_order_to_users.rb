class AddSortingOrderToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :sorting_order, :string, default: nil
  end
end
