class AddPerformanceIndexes < ActiveRecord::Migration[7.1]
  def change
    # Index for filtering shop_items by approved status (commonly used in queries)
    add_index :shop_items, :approved unless index_exists?(:shop_items, :approved)
    
    # Composite index for shopping_list_items queries that filter by list, deleted_at, and purchased
    add_index :shopping_list_items, [:shopping_list_id, :deleted_at, :purchased], 
              name: 'index_shopping_list_items_on_list_deleted_purchased'
              
    # Index for shopping_list_id alone (helps with foreign key queries)
    add_index :shopping_list_items, :shopping_list_id unless index_exists?(:shopping_list_items, :shopping_list_id)
  end
end
