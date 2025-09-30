ActiveAdmin.register ShoppingListItem do
  menu parent: "Shopping Lists", label: "Shopping List Items"

  # Permit parameters for strong parameter handling
  permit_params :title, :quantity, :priority, :purchased, :shopping_list_id, :category_id, :user_id

  scope :all
  scope :without_category, -> { where(without_category: true) }

  # Customize the index page
  index do
    selectable_column
    id_column
    column :title
    column :quantity
    column :priority
    column :purchased
    column :shopping_list
    column :category
    column :user
    column :created_at
    column :updated_at
    actions
  end

  # Customize the form for creating/editing a ShoppingListItem
  form do |f|
    f.inputs "Shopping List Item Details" do
      f.input :title
      f.input :quantity
      f.input :priority
      f.input :purchased
      f.input :shopping_list, as: :select, collection: ShoppingList.all.map { |sl| [sl.display_name, sl.id] }
      f.input :category, as: :select, collection: Category.all.map { |c| [c.title, c.id] }
      f.input :user, as: :select, collection: User.all.map { |u| [u.hash, u.id] }
    end
    f.actions
  end

  # Customize the show page
  show do
    attributes_table do
      row :id
      row :title
      row :quantity
      row :priority
      row :purchased
      row :shopping_list
      row :category
      row :user
      row :created_at
      row :updated_at
    end

    # Add a panel to create a new Category
    if shopping_list_item.category.nil?
      panel "Create a New Category" do
        form_with url: admin_create_category_from_shopping_list_item_path, method: :post, local: true do |f|
          concat f.hidden_field :shopping_list_item_id, value: shopping_list_item.id
          concat content_tag(:div, f.text_field(:title, placeholder: "Enter Category Title", value: shopping_list_item.title), class: "form-group")
          concat content_tag(:div, select_tag(:parent_id, options_for_select(Category.parent_options_for_select), prompt: "Select Parent Category"), class: "form-group")
          concat f.submit "Create Category", class: "btn btn-primary"
        end
      end
    end
  end

  # Add filters for the index page
  filter :title
  filter :quantity
  filter :priority
  filter :purchased
  filter :shopping_list
  filter :category
  filter :user
  filter :created_at
end
