class BackfillUuidForCategories < ActiveRecord::Migration[7.0]
  def up
    Category.where(uuid: nil).find_each do |category|
      category.update_column(:uuid, SecureRandom.uuid)
    end
  end

  def down
    # No-op: You can't "un-backfill" UUIDs
  end
end
