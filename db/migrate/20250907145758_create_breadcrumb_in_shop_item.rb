class CreateBreadcrumbInShopItem < ActiveRecord::Migration[7.1]
  def change
    add_column :shop_items, :breadcrumb, :string
    add_index :shop_items, :breadcrumb
  end
end
