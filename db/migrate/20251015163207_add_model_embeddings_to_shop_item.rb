class AddModelEmbeddingsToShopItem < ActiveRecord::Migration[7.1]
  def change
    add_column :shop_items, :model_embedding, :jsonb
    add_column :shop_items, :needs_model_embedding_update, :boolean, default: false, null: false
    add_index :shop_items, :model_embedding, using: :gin
  end
end
