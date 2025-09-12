ActiveAdmin.register Category do
  # Permit parameters for create/update actions
  permit_params :title, :slug, :category_type, :sort_order, :parent_id

  controller do
    def create
      @category = Category.new(permitted_params[:category])
      if @category.save
        # Redirect to the parent category show page if parent_id is present
        if @category.parent_id.present?
          redirect_to admin_category_path(@category.parent_id), notice: "Child category created successfully."
        else
          redirect_to admin_category_path(@category), notice: "Category created successfully."
        end
      else
        render :new
      end
    end
  end

  # Configure the index page
  index do
    selectable_column
    id_column
    column :title do |category|
      # Indent based on depth to show hierarchy
      indent = "&nbsp;" * (category.depth * 4)
      raw "#{indent}#{category.title}"
    end
    column :category_type do |category|
      status_tag category.category_type, class: case category.category_type
                                         when "root" then "blue"
                                         when "category" then "green"
                                         when "subcategory" then "orange"
                                         when "product" then "red"
                                         end
    end
    column :parent do |category|
      link_to category.parent.title, admin_category_path(category.parent) if category.parent
    end
    column :children_count do |category|
      category.children.count
    end
    column :shop_items_count do |category|
      category.shop_items.count if category.product?
    end
    column :slug
    column :path
    actions
  end

  # Configure filters
  filter :title
  filter :category_type, as: :select, collection: Category.category_types.keys.map { |key| [key.humanize, key] }
  filter :parent, as: :select, collection: proc { Category.parent_options_for_select }
  filter :created_at

  # Configure the form
  form do |f|
    f.inputs "Category Details" do
      f.input :title
      f.input :parent, as: :select,
                       collection: Category.parent_options_for_select,
                       include_blank: "None (Root Category)",
                       hint: "Select a parent category. Products cannot have children."
      f.input :sort_order, hint: "Order within parent category"
    end
    f.actions
  end

  # Configure the show page
  show do
    attributes_table do
      row :id
      row :title
      row :category_type do |category|
        status_tag category.category_type, class: case category.category_type
                                           when "root" then "blue"
                                           when "category" then "green"
                                           when "subcategory" then "orange"
                                           when "product" then "red"
                                           end
      end
      row :parent do |category|
        if category.parent
          link_to category.parent.title, admin_category_path(category.parent)
        else
          "Root Category"
        end
      end
      row :breadcrumbs do |category|
        category.breadcrumbs.map(&:title).join(" > ")
      end
      row :path
      row :sort_order
      row :slug
      row :depth
      row :sort_order
      row :lft
      row :rgt
      row :created_at
      row :updated_at
    end

    panel "Child Categories (#{category.children.count})" do
      table_for category.children.order(:sort_order) do
        column :title do |child|
          link_to child.title, admin_category_path(child)
        end
        column :category_type do |child|
          status_tag child.category_type
        end
        column :children_count do |child|
          child.children.count
        end
        column :shop_items_count do |child|
          child.shop_items.count if child.product?
        end
        column :sort_order do |child|
          child.sort_order
        end
      end
    end

    if !category.product?
      panel "Add New Child Category" do
        # Use a Rails form with POST to admin_categories_path
        form action: admin_categories_path, method: :post do |f|
          # CSRF token for Rails authenticity
          input type: "hidden", name: "authenticity_token", value: form_authenticity_token

          div class: "inputs" do
            input type: "hidden", name: "category[parent_id]", value: category.id
            div do
              label "Title", for: "category_title"
              input type: "text", name: "category[title]", id: "category_title", required: true
            end
            div do
              input type: "hidden", name: "category[sort_order]", id: "category_sort_order", value: (category.children.maximum(:sort_order) || 0) + 1
            end
          end
          div class: "actions" do
            input type: "submit", value: "Create Child Category", class: "button"
          end
        end
      end
    end

    # Show associated shop items if this is a product category
    if category.product?
      panel "Associated Shop Items (#{category.shop_items.count})" do
        table_for category.shop_items.limit(20) do
          column :title do |item|
            link_to item.title, admin_shop_item_path(item)
          end
          column :sort_order
          column :created_at
          column :actions do |item|
            link_to "Remove from Category",
                    remove_shop_item_admin_category_path(category, shop_item_id: item.id),
                    method: :delete,
                    data: { confirm: "Remove this item from category?" },
                    class: "button small"
          end
        end

        if category.shop_items.count > 20
          div style: "margin-top: 10px;" do
            link_to "View all #{category.shop_items.count} items",
                    admin_shop_items_path(q: { category_id_eq: category.id }),
                    class: "button"
          end
        end
      end
    end
  end

  # Replace the scopes section (around line 132) with:
  scope :all
  scope :roots, -> { where(parent_id: nil) }
  scope :products, -> { where(category_type: :product) }
  scope :categories_only, -> { where.not(category_type: :product) }
  scope :with_shop_items, -> { joins(:shop_items).distinct }

  # Custom collection action to rebuild tree (if needed)
  collection_action :rebuild_tree, method: :post do
    Category.rebuild!
    redirect_to collection_path, notice: "Category tree has been rebuilt."
  end

  # Add collection action for importing categories
  collection_action :import_categories, method: :post do
    begin
      # Path to your XML file - adjust as needed
      xml_file_path = Rails.root.join("db", "seeds", "shop_item_categories.xml")

      if File.exist?(xml_file_path)
        # Run async with background job (recommended)
        CategoryImportJob.perform_later(xml_file_path.to_s)
        #redirect_to collection_path, notice: "Category import started in background. Check logs for progress."
      else
        redirect_to collection_path, alert: "Categories XML file not found at #{xml_file_path}"
      end
    rescue => e
      redirect_to collection_path, alert: "Error starting import: #{e.message}"
    end
  end

  # Add action item for rebuilding tree
  action_item :rebuild_tree, only: :index do
    link_to "Rebuild Tree", rebuild_tree_admin_categories_path,
            method: :post,
            data: { confirm: "This will rebuild the category tree structure. Continue?" },
            class: "button"
  end

  # Add action item for importing categories
  action_item :import_categories, only: :index do
    link_to "Import Categories", import_categories_admin_categories_path,
            method: :post,
            data: { confirm: "This will import categories from XML. This may take a while. Continue?" },
            class: "button"
  end

  # Add member action for removing shop items from category
  member_action :remove_shop_item, method: :delete do
    shop_item_id = params[:shop_item_id]

    if shop_item_id.present?
      shop_item = ShopItem.find(shop_item_id)

      begin
        # Remove the association between category and shop item
        resource.shop_items.delete(shop_item)
        redirect_to admin_category_path(resource),
                    notice: "Successfully removed '#{shop_item.title}' from category '#{resource.title}'"
      rescue => e
        redirect_to admin_category_path(resource),
                    alert: "Error removing shop item: #{e.message}"
      end
    else
      redirect_to admin_category_path(resource),
                  alert: "No shop item specified for removal"
    end
  end

  # Batch actions
  batch_action :move_to_parent, form: {
                                  parent_id: proc { [["Root (No Parent)", nil]] + Category.parent_options_for_select },
                                } do |ids, inputs|
    batch_inputs = JSON.parse(params[:batch_action_inputs])
    parent_id = batch_inputs["parent_id"].presence

    begin
      categories = Category.where(id: ids)
      parent = parent_id ? Category.find(parent_id) : nil

      categories.each do |category|
        category.update!(parent: parent)
      end

      parent_name = parent ? parent.title : "Root"
      redirect_to collection_path,
                  notice: "#{categories.count} categories moved to #{parent_name}."
    rescue => e
      redirect_to collection_path,
                  alert: "Error moving categories: #{e.message}"
    end
  end
end
