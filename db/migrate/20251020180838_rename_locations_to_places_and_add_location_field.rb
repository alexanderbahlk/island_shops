class RenameLocationsToPlacesAndAddLocationField < ActiveRecord::Migration[7.1]
  def change
    # Update the foreign key to reference the places table
    remove_foreign_key :shop_items, :locations

    # Rename the table
    rename_table :locations, :places

    # Add the new location field
    add_column :places, :location, :string

    # Rename the location_id column in shop_items to place_id
    rename_column :shop_items, :location_id, :place_id

    add_foreign_key :shop_items, :places, column: :place_id
  end
end
