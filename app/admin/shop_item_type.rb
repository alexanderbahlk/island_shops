ActiveAdmin.register ShopItemType do
  menu parent: "Shop Categories", priority: 3
  permit_params :title

  # Configure the index page
  index do
    selectable_column
    id_column
    column :title
    column :subcategories_count do |shop_item_type|
      shop_item_type.shop_item_sub_categories.count
    end
    column :subcategories do |shop_item_type|
      if shop_item_type.shop_item_sub_categories.any?
        shop_item_type.shop_item_sub_categories.limit(3).map(&:title).join(", ") +
        (shop_item_type.shop_item_sub_categories.count > 3 ? "..." : "")
      else
        "None"
      end
    end
    column :created_at
    actions
  end

  # Configure filters
  filter :title
  filter :shop_item_sub_categories, as: :select, collection: proc { ShopItemSubCategory.all.pluck(:title, :id) }
  filter :created_at

  # Configure the show page
  show do
    attributes_table do
      row :id
      row :title
      row :created_at
      row :updated_at
    end

    panel "Associated Subcategories" do
      if shop_item_type.shop_item_sub_categories.any?
        table_for shop_item_type.shop_item_sub_categories.includes(:shop_item_category) do
          column :category do |subcategory|
            link_to subcategory.shop_item_category.title, admin_shop_item_category_path(subcategory.shop_item_category)
          end
          column :subcategory do |subcategory|
            link_to subcategory.title, admin_shop_item_sub_category_path(subcategory)
          end
          column :created_at
        end
      else
        para "No subcategories associated with this type."
      end
    end
  end

  # Configure the form
  form do |f|
    f.inputs "Shop Item Type Details" do
      f.input :title, placeholder: "Enter type name (e.g., Wine, Beer, Milk, etc.)"
    end

    f.inputs "Associate with Subcategories" do
      f.input :shop_item_sub_categories,
              as: :check_boxes,
              collection: ShopItemSubCategory.joins(:shop_item_category)
                .select("shop_item_sub_categories.*, shop_item_categories.title as category_title")
                .map { |sc| ["#{sc.shop_item_category.title} > #{sc.title}", sc.id] }
                .sort
    end

    f.actions
  end

  # Batch actions
  batch_action :assign_to_subcategory,
               form: {
                 subcategory_id: ShopItemSubCategory.joins(:shop_item_category)
                   .pluck(Arel.sql("CONCAT(shop_item_categories.title, ' > ', shop_item_sub_categories.title)"), "shop_item_sub_categories.id"),
               } do |ids, inputs|
    subcategory_id = inputs["subcategory_id"]

    if subcategory_id.present?
      subcategory = ShopItemSubCategory.find(subcategory_id)

      ShopItemType.where(id: ids).find_each do |type|
        unless type.shop_item_sub_categories.include?(subcategory)
          ShopItemSubCategoryType.create!(
            shop_item_type: type,
            shop_item_sub_category: subcategory,
          )
        end
      end

      redirect_to collection_path,
                  notice: "#{ids.count} types have been assigned to '#{subcategory.shop_item_category.title} > #{subcategory.title}'."
    else
      redirect_to collection_path, alert: "Please select a subcategory."
    end
  end

  batch_action :remove_from_subcategory,
               form: {
                 subcategory_id: ShopItemSubCategory.joins(:shop_item_category)
                   .pluck(Arel.sql("CONCAT(shop_item_categories.title, ' > ', shop_item_sub_categories.title)"), "shop_item_sub_categories.id"),
               } do |ids, inputs|
    subcategory_id = inputs["subcategory_id"]

    if subcategory_id.present?
      subcategory = ShopItemSubCategory.find(subcategory_id)

      ShopItemSubCategoryType.where(
        shop_item_type_id: ids,
        shop_item_sub_category_id: subcategory_id,
      ).destroy_all

      redirect_to collection_path,
                  notice: "#{ids.count} types have been removed from '#{subcategory.shop_item_category.title} > #{subcategory.title}'."
    else
      redirect_to collection_path, alert: "Please select a subcategory."
    end
  end

  # Custom collection action to show types without subcategories
  collection_action :orphaned, method: :get do
    @orphaned_types = ShopItemType.left_joins(:shop_item_sub_categories)
                                  .where(shop_item_sub_categories: { id: nil })
    render "admin/shop_item_types/orphaned"
  end

  # Add link to orphaned types in the index
  action_item :orphaned_types, only: :index do
    link_to "View Orphaned Types", orphaned_admin_shop_item_types_path, class: "button"
  end
end
