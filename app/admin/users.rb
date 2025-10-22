ActiveAdmin.register User do
  # Permit parameters for strong parameter handling
  permit_params :app_hash

  # Customize the index page
  index do
    selectable_column
    id_column
    column :app_hash
    column :created_at
    column :updated_at
    column :shop_item_count do |user|
      user.shop_items.size
    end
    column :shopping_lists_count do |user|
      user.shopping_lists.size
    end
    column :shopping_list_items_count do |user|
      user.shopping_list_items.size
    end
    actions
  end

  # Customize the form for creating/editing a User
  form do |f|
    f.inputs "User Details" do
      f.input :app_hash
    end
    f.actions
  end

  # Customize the show page
  show do
    attributes_table do
      row :id
      row :app_hash
      row :created_at
      row :updated_at
    end

    panel "Shop Items" do
      table_for user.shop_items do
        column :id
        column :title
        column :created_at
      end
    end

    panel "Shopping Lists" do
      table_for user.shopping_lists do
        column :id
        column :display_name
        column :slug
        column :created_at
      end
    end

    panel "Shopping List Items" do
      table_for user.shopping_list_items do
        column :id
        column :title
        column :quantity
        column :purchased
        column :created_at
      end
    end
  end

  # Add filters for the index page
  filter :app_hash
  filter :created_at
end
