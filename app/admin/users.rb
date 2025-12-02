ActiveAdmin.register User do
  # Permit parameters for strong parameter handling
  permit_params :app_hash, :tutorial_step

  # Customize the index page
  index do
    selectable_column
    id_column
    column :app_hash
    column :tutorial_step
    column :shop_item_count do |user|
      user.shop_items.size
    end
    column :shopping_lists_count do |user|
      user.shopping_lists.size
    end
    column :shopping_list_items_count do |user|
      user.shopping_list_items.size
    end
    column :human_readable_device_data do |user|
      pre JSON.pretty_generate(user.human_readable_device_data)
    end
    column :last_activity_at
    column :updated_at
    actions
  end

  # Customize the form for creating/editing a User
  form do |f|
    f.inputs 'User Details' do
      f.input :app_hash
    end
    f.inputs 'Tutorial' do
      f.input :tutorial_step
    end
    f.actions
  end

  # Customize the show page
  show do
    attributes_table do
      row :id
      row :app_hash
      row :tutorial_step
      row :active_shopping_list
      row :group_shopping_lists_items_by
      row :shop_item_stock_status_filter
      row :last_activity_at
      row :device_data do |user|
        # device_data may already be a Hash (from jsonb) or a JSON string.
        data = user.device_data
        data = JSON.parse(data) if data.is_a?(String)
        pre JSON.pretty_generate(data || {})
      end
      row :created_at
      row :updated_at
    end

    panel 'Shop Items' do
      table_for user.shop_items do
        column :id
        column :title
        column :created_at
      end
    end

    panel 'Shopping Lists' do
      table_for user.shopping_lists do
        column :id
        column :display_name do |shopping_list|
          link_to shopping_list.display_name, admin_shopping_list_path(shopping_list)
        end
        column :slug
        column :created_at
      end
    end

    panel 'Shopping List Items' do
      table_for user.shopping_list_items do
        column :id
        column :title
        column :quantity
        column :purchased
        column :created_at
      end
    end

    panel 'Feedback' do
      table_for user.feedbacks do
        column :id
        column :content
        column :created_at
      end
    end
  end

  # Add filters for the index page
  filter :app_hash
  filter :created_at
end
