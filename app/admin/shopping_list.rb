ActiveAdmin.register ShoppingList do
  # Permit parameters for strong parameter handling
  permit_params :display_name, :slug

  # Customize the index page
  index do
    selectable_column
    id_column
    column :display_name
    column :slug
    column :shopping_list_items_count do |shopping_list|
      shopping_list.shopping_list_items.size
    end
    column :created_at
    column :updated_at
    actions
  end

  # Customize the form for creating/editing a ShoppingList
  form do |f|
    f.inputs "Shopping List Details" do
      f.input :display_name
    end
    f.actions
  end

  # Customize the show page
  show do
    attributes_table do
      row :id
      row :display_name
      row :slug
      row :created_at
      row :updated_at
    end

    panel "Shopping List Items" do
      table_for shopping_list.shopping_list_items do
        column :uuid
        column :title
        column :purchased
        column :quantity
        column :category do |item|
          item.category&.title
        end
      end
    end
  end

  # Add filters for the index page
  filter :display_name
  filter :slug
  filter :created_at
end
