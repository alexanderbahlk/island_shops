class BackfillUuidForShopItems < ActiveRecord::Migration[7.1]
  def up
    add_column :shop_items, :uuid, :uuid
    ShopItem.where(uuid: nil).find_each do |item|
      item.update_column(:uuid, SecureRandom.uuid)
    end
  end

  def down
    # No-op: You can't "un-backfill" UUIDs
  end
end
