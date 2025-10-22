class RemoveUniqueConstraintOnPlacesTitle < ActiveRecord::Migration[7.1]
  def change
    # Remove the unique index on the title column
    remove_index :places, name: "index_places_on_title"

    # Add a non-unique index on the title column (optional, for performance)
    add_index :places, :title

    remove_column :places, :description, :text
  end
end
