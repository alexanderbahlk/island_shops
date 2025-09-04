ActiveAdmin.register ShopItemSubCategory do
  menu parent: "Shop Categories", priority: 2

  # Permit parameters for create/update actions
  permit_params :title

  # Configure the index page
  index do
    selectable_column
    id_column
    column :title
    column :shop_item_category do |sub_category|
      #link to the associated category
      # Check if the association exists to avoid errors
      link_to sub_category.shop_item_category.title, admin_shop_item_category_path(sub_category.shop_item_category) if sub_category.shop_item_category
    end
    column :created_at
    actions
  end
  # Configure filters for the index page
  # Add a filter for the associated category
  # This assumes a belongs_to association named :shop_item_category
  filter :shop_item_category, as: :select, collection: proc { ShopItemCategory.all.pluck(:title, :id) }
  filter :title
  filter :created_at
  # Configure the form for create/edit
  # Add a dropdown to select the associated category
  form do |f|
    f.inputs "Shop Item Subcategory Details" do
      f.input :shop_item_category, as: :select, collection: ShopItemCategory.all.pluck(:title, :id), include_blank: false
      f.input :title
    end
    f.actions
  end
  # Configure the show page
  show do
    attributes_table do
      row :id
      row :shop_item_category do |sub_category|
        link_to sub_category.shop_item_category.title, admin_shop_item_category_path(sub_category.shop_item_category) if sub_category.shop_item_category
      end
      row :title
      row :created_at
      row :updated_at
    end
  end
end
