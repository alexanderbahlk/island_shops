class AddSynonymsToCategories < ActiveRecord::Migration[6.0]
  def change
    add_column :categories, :synonyms, :text, array: true, default: []
  end
end
