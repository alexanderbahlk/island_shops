class AddUuidToCategories < ActiveRecord::Migration[7.1]
  def change
    add_column :categories, :uuid, :uuid
  end
end
