ActiveAdmin.register ShopItemSubCategory do
  menu parent: "Shop Categories", priority: 2

  # Permit parameters for create/update actions
  permit_params :title, :shop_item_category_id, shop_item_type_ids: []

  # Configure the index page
  index do
    selectable_column
    id_column
    column :title
    column :shop_item_category do |sub_category|
      link_to sub_category.shop_item_category.title, admin_shop_item_category_path(sub_category.shop_item_category) if sub_category.shop_item_category
    end
    column :types_count do |sub_category|
      sub_category.shop_item_types.count
    end
    column :types do |sub_category|
      if sub_category.shop_item_types.any?
        sub_category.shop_item_types.limit(3).map(&:title).join(", ") +
        (sub_category.shop_item_types.count > 3 ? "..." : "")
      else
        "None"
      end
    end
    column :created_at
    actions
  end

  # Configure filters for the index page
  filter :shop_item_category, as: :select, collection: proc { ShopItemCategory.all.pluck(:title, :id) }
  filter :shop_item_sub_category_types_shop_item_type_id, as: :select,
                                                          collection: proc { ShopItemType.all.pluck(:title, :id) },
                                                          label: "Shop Item Types"
  filter :title
  filter :created_at

  # Configure the form for create/edit
  form do |f|
    f.inputs "Shop Item Subcategory Details" do
      f.input :shop_item_category, as: :select, collection: ShopItemCategory.all.pluck(:title, :id), include_blank: false
      f.input :title
    end

    f.inputs "Associated Types" do
      f.input :shop_item_types,
              as: :check_boxes,
              collection: ShopItemType.all.order(:title).map { |type| [type.title, type.id] }
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

    panel "Associated Types" do
      if shop_item_sub_category.shop_item_types.any?
        table_for shop_item_sub_category.shop_item_types.order(:title) do
          column :id
          column :title do |type|
            link_to type.title, admin_shop_item_type_path(type)
          end
          column :other_subcategories do |type|
            other_subcategories = type.shop_item_sub_categories.where.not(id: shop_item_sub_category.id)
            if other_subcategories.any?
              other_subcategories.limit(2).map { |sc| "#{sc.shop_item_category.title} > #{sc.title}" }.join(", ") +
              (other_subcategories.count > 2 ? "..." : "")
            else
              "None"
            end
          end
          column :created_at
          column "Actions" do |type|
            link_to "Remove", admin_shop_item_sub_category_path(shop_item_sub_category, remove_type: type.id),
                    method: :patch,
                    confirm: "Remove #{type.title} from this subcategory?",
                    class: "button"
          end
        end
      else
        para "No types associated with this subcategory."
        para do
          link_to "Add Types", edit_admin_shop_item_sub_category_path(shop_item_sub_category), class: "button"
        end
      end
    end
  end

  # Custom member action to add/remove types
  member_action :add_remove_type, method: :patch do
    if params[:add_type].present?
      type = ShopItemType.find(params[:add_type])
      unless resource.shop_item_types.include?(type)
        ShopItemSubCategoryType.create!(
          shop_item_sub_category: resource,
          shop_item_type: type,
        )
        redirect_to admin_shop_item_sub_category_path(resource),
                    notice: "Successfully added '#{type.title}' to this subcategory."
      else
        redirect_to admin_shop_item_sub_category_path(resource),
                    alert: "'#{type.title}' is already associated with this subcategory."
      end
    elsif params[:remove_type].present?
      type = ShopItemType.find(params[:remove_type])
      ShopItemSubCategoryType.where(
        shop_item_sub_category: resource,
        shop_item_type: type,
      ).destroy_all
      redirect_to admin_shop_item_sub_category_path(resource),
                  notice: "Successfully removed '#{type.title}' from this subcategory."
    else
      redirect_to admin_shop_item_sub_category_path(resource),
                  alert: "Invalid action."
    end
  end

  # Batch actions
  batch_action :assign_types,
               form: {
                 type_ids: ShopItemType.all.pluck(:title, :id),
               } do |ids, inputs|
    type_ids = inputs["type_ids"]

    if type_ids.present?
      types = ShopItemType.where(id: type_ids)

      ShopItemSubCategory.where(id: ids).find_each do |subcategory|
        types.each do |type|
          unless subcategory.shop_item_types.include?(type)
            ShopItemSubCategoryType.create!(
              shop_item_sub_category: subcategory,
              shop_item_type: type,
            )
          end
        end
      end

      redirect_to collection_path,
                  notice: "Successfully assigned #{types.count} type(s) to #{ids.count} subcategory(ies)."
    else
      redirect_to collection_path, alert: "Please select types to assign."
    end
  end

  # Collection action to show subcategories without types
  collection_action :without_types, method: :get do
    @subcategories_without_types = ShopItemSubCategory.left_joins(:shop_item_types)
      .where(shop_item_types: { id: nil })
      .includes(:shop_item_category)
    render "admin/shop_item_sub_categories/without_types"
  end

  # Add link to subcategories without types in the index
  action_item :without_types, only: :index do
    link_to "View Subcategories Without Types", without_types_admin_shop_item_sub_categories_path, class: "button"
  end
end
