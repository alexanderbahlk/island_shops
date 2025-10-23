class AddLatitudeAndLongitudeToPlaces < ActiveRecord::Migration[7.1]
  def change
    add_column :places, :latitude, :decimal, precision: 10, scale: 6
    add_column :places, :longitude, :decimal, precision: 10, scale: 6
  end
end
