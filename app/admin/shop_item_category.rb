ActiveAdmin.register ShopItemCategory do
  menu parent: "Shop Categories", priority: 1
  # Permit parameters for create/update actions
  permit_params :title

  # Configure the index page
  index do
    selectable_column
    id_column
    column :title
    column :created_at
    actions
  end

  # Configure filters for the index page
  filter :title
  filter :created_at

  # Configure the form for create/edit
  form do |f|
    f.inputs "Shop Item Category Details" do
      f.input :title
    end
    f.actions
  end

  # Configure the show page
  show do
    attributes_table do
      row :id
      row :title
      row :created_at
      row :updated_at
    end

    panel "Subcategories" do
      table_for shop_item_category.shop_item_sub_categories do
        column :id
        column :title
        column :created_at
        column :updated_at
      end
    end

    panel "Shop Items in this Category" do
      table_for shop_item_category.shop_items do
        column :id
        column :title
        column :shop
        column :approved
        column :created_at
        column "" do |shop_item|
          link_to "View", admin_shop_item_path(shop_item)
        end
        column "" do |shop_item|
          link_to "Edit", edit_admin_shop_item_path(shop_item)
        end
      end
    end
  end
end
