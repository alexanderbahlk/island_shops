class CreateLocations < ActiveRecord::Migration[7.1]
  def change
    create_table :locations do |t|
      t.string :title, null: false
      t.string :uuid, default: -> { "gen_random_uuid()" }, null: false
      t.text :description
      t.boolean :is_online, default: false, null: false

      t.timestamps
    end

    add_index :locations, :title, unique: true
    add_index :locations, :uuid, unique: true

    add_reference :shop_items, :location, foreign_key: true, index: true
  end
end
