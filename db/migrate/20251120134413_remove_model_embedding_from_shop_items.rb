class RemoveModelEmbeddingFromShopItems < ActiveRecord::Migration[7.1]
  def change
    # Remove the GIN index on model_embedding first
    remove_index :shop_items, name: :index_shop_items_on_model_embedding, if_exists: true
    
    remove_column :shop_items, :model_embedding, :jsonb
    remove_column :shop_items, :needs_model_embedding_update, :boolean, default: false, null: false
  end
end
