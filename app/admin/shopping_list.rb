ActiveAdmin.register ShoppingList do
  # Permit parameters for strong parameter handling
  permit_params :display_name, :slug

  # Customize the index page
  index do
    selectable_column
    id_column
    column :display_name
    column :slug
    column :users do |shopping_list|
      shopping_list.users.map(&:id).join(", ")
    end
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
      row :users do |shopping_list|
        shopping_list.users.map { |user| link_to user.id, admin_user_path(user) }.join(", ").html_safe
      end
      row :created_at
      row :updated_at
    end

    panel "Shopping List Items" do
      table_for shopping_list.shopping_list_items do
        column :uuid do |item|
          link_to item.uuid, admin_shopping_list_item_path(item)
        end
        column :title
        column :purchased
        column :priority
        column :quantity
        column :category do |item|
          if item.category
            link_to item.category.title, admin_category_path(item.category)
          end
        end
      end
    end
  end

  # Add filters for the index page
  filter :display_name
  filter :slug
  filter :created_at
end
