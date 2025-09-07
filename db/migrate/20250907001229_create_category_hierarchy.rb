# Single hierarchical table with self-referencing relationship
class CreateCategoryHierarchy < ActiveRecord::Migration[7.0]
  def change
    create_table :categories do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.integer :category_type, null: false, default: 0
      t.references :parent, null: true, foreign_key: { to_table: :categories }
      t.integer :sort_order, default: 0

      # Materialized path for efficient queries
      t.string :path # e.g., "food/fresh-food/vegetables"
      t.integer :depth, default: 0

      # For faster tree operations
      t.integer :lft, null: false
      t.integer :rgt, null: false

      t.timestamps
    end

    # Indexes for performance
    add_index :categories, [:parent_id, :slug], unique: true, name: "index_categories_on_parent_id_and_slug"
    add_index :categories, :category_type
    add_index :categories, :path
    add_index :categories, [:lft, :rgt]
    add_index :categories, [:parent_id, :sort_order]
  end
end
