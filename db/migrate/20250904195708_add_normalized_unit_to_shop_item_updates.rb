class AddNormalizedUnitToShopItemUpdates < ActiveRecord::Migration[7.1]
  def change
    add_column :shop_item_updates, :normalized_unit, :string
  end
end
