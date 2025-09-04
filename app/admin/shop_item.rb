ActiveAdmin.register ShopItem do
  # Permit parameters for create/update actions
  permit_params :shop, :url, :title, :display_title, :image_url, :size, :unit, :location, :product_id, :approved, :needs_another_review, :shop_item_category_id, :shop_item_sub_category_id

  # Configure the index page
  index do
    selectable_column
    id_column
    column :shop
    column :title do |shop_item|
      link_to shop_item.title, shop_item.url, target: "_blank"
    end
    column :display_title do |shop_item|
      best_in_place shop_item, :display_title,
                    as: :input,
                    url: admin_shop_item_path(shop_item),
                    placeholder: "Click to edit display title",
                    class: "bip-input-unit",
                    html_attrs: { style: "width: 200px" }
    end
    column :image_url do |shop_item|
      if shop_item.image_url.present?
        image_tag shop_item.image_url, size: "50x50", style: "object-fit: cover;"
      end
    end
    column :latest_price do |shop_item|
      latest_update = shop_item.shop_item_updates.order(created_at: :desc).first
      if latest_update&.price
        number_to_currency(latest_update.price)
      else
        "N/A"
      end
    end
    column :size do |shop_item|
      best_in_place shop_item, :size,
                    as: :input,
                    url: admin_shop_item_path(shop_item),
                    placeholder: "Click to edit size",
                    class: "bip-input-unit",
                    html_attrs: { style: "width: 100px" }
    end
    column :unit do |shop_item|
      best_in_place shop_item, :unit,
                    as: :select,
                    url: admin_shop_item_path(shop_item),
                    collection: UnitParser::VALID_UNITS.map { |unit| [unit, unit] },
                    html_attrs: { style: "cursor: pointer; min-width: 30px;" },
                    class: "bip-select-unit"
    end
    column :shop_item_category do |shop_item|
      #do a link into the category
      if shop_item.shop_item_category.present?
        link_to shop_item.shop_item_category.title, admin_shop_item_category_path(shop_item.shop_item_category)
      else
        "None"
      end
    end
    column :shop_item_sub_category do |shop_item|
      #do a link into the category
      # Check if the association exists to avoid errors
      if shop_item.shop_item_sub_category.present?
        link_to shop_item.shop_item_sub_category.title, admin_shop_item_sub_category_path(shop_item.shop_item_sub_category)
      else
        "None"
      end
    end
    column :approved do |shop_item|
      best_in_place shop_item, :approved,
                    as: :checkbox,
                    url: admin_shop_item_path(shop_item),
                    html_attrs: { style: "cursor: pointer;" },
                    class: "bip-checkbox-approved"
    end
    column :needs_another_review do |shop_item|
      best_in_place shop_item, :needs_another_review,
                    as: :checkbox,
                    url: admin_shop_item_path(shop_item),
                    html_attrs: { style: "cursor: pointer;" },
                    class: "bip-checkbox-review"
    end
    column :created_at
    actions
  end

  # Configure filters for the index page
  filter :shop
  filter :title
  filter :url
  filter :location
  filter :approved
  filter :needs_another_review
  #include null option for category and subcategory filters
  filter :shop_item_category, as: :select, collection: proc { ShopItemCategory.all.pluck(:title, :id) }, include_blank: "None"
  filter :shop_item_sub_category, as: :select, collection: proc { ShopItemSubCategory.all.pluck(:title, :id) }, include_blank: "None"
  filter :created_at

  # Configure the form for create/edit
  form html: { data: { sub_categories: ShopItemSubCategory.joins(:shop_item_category).pluck("shop_item_categories.id", "shop_item_sub_categories.id", "shop_item_sub_categories.title").group_by(&:first).transform_values { |v| v.map { |item| [item[2], item[1]] } }.to_json } } do |f|
    f.inputs "Shop Item Details" do
      f.input :shop, as: :select, collection: Shop::ALLOWED, include_blank: false
      f.input :url, placeholder: "https://example.com/product"
      f.input :title
      f.input :display_title, hint: "Optional: Custom display name for the item"
      f.input :shop_item_category, as: :select, collection: ShopItemCategory.all.pluck(:title, :id), include_blank: true, input_html: { id: "shop_item_category_select" }
      f.input :shop_item_sub_category, as: :select, collection: f.object.shop_item_category.present? ? f.object.shop_item_category.shop_item_sub_categories.pluck(:title, :id) : [], include_blank: true, input_html: { id: "shop_item_sub_category_select" }, wrapper_html: { id: "shop_item_sub_category_wrapper", style: f.object.shop_item_category.present? ? "" : "display: none;" }
      f.input :image_url, placeholder: "https://example.com/image.jpg"
      f.input :size
      f.input :unit, as: :select, collection: UnitParser::VALID_UNITS.map { |unit| [unit, unit] }, include_blank: false
      f.input :location
      f.input :product_id
      f.input :approved, as: :boolean, hint: "Check to approve this item for public listing"
      f.input :needs_another_review, as: :boolean, hint: "Check if the item needs another review even if approved"
    end
    f.actions
  end

  # Configure the show page
  show do
    attributes_table do
      row :id
      row :shop
      row :title
      row :display_title do |shop_item|
        best_in_place shop_item, :display_title,
                      as: :input,
                      url: admin_shop_item_path(shop_item),
                      placeholder: "Click to edit display_title",
                      class: "bip-input-unit",
                      html_attrs: { style: "width: 200px" }
      end
      row :shop_item_category do |shop_item|
        #do a link into the category
        if shop_item.shop_item_category.present?
          link_to shop_item.shop_item_category.title, admin_shop_item_category_path(shop_item.shop_item_category)
        else
          "None"
        end
      end
      row :shop_item_sub_category do |shop_item|
        #do a link into the category
        if shop_item.shop_item_sub_category.present?
          link_to shop_item.shop_item_sub_category.title, admin_shop_item_sub_category_path(shop_item.shop_item_sub_category)
        else
          "None"
        end
      end
      row :url do |shop_item|
        link_to shop_item.url, shop_item.url, target: "_blank" if shop_item.url.present?
      end
      row :image_url do |shop_item|
        if shop_item.image_url.present?
          div do
            image_tag shop_item.image_url, style: "max-width: 300px; height: auto;"
          end
        end
      end
      row :size do |shop_item|
        best_in_place shop_item, :size,
                      as: :input,
                      url: admin_shop_item_path(shop_item),
                      placeholder: "Click to edit size",
                      class: "bip-input-unit",
                      html_attrs: { style: "width: 100px" }
      end
      row :unit do |shop_item|
        best_in_place shop_item, :unit,
                      as: :select,
                      url: admin_shop_item_path(shop_item),
                      collection: UnitParser::VALID_UNITS.map { |unit| [unit, unit] },
                      html_attrs: { style: "cursor: pointer; min-width: 30px;" },
                      class: "bip-select-unit"
      end
      row :latest_price do |shop_item|
        latest_update = shop_item.shop_item_updates.order(created_at: :desc).first
        if latest_update&.price
          number_to_currency(latest_update.price)
        else
          "N/A"
        end
      end
      row :location
      row :product_id
      row :approved do |shop_item|
        best_in_place shop_item, :approved,
                      as: :checkbox,
                      url: admin_shop_item_path(shop_item),
                      html_attrs: { style: "cursor: pointer;" },
                      class: "bip-checkbox-approved"
      end
      row :needs_another_review do |shop_item|
        best_in_place shop_item, :needs_another_review,
                      as: :checkbox,
                      url: admin_shop_item_path(shop_item),
                      html_attrs: { style: "cursor: pointer;" },
                      class: "bip-checkbox-review"
      end
      row :created_at
      row :updated_at
    end

    # Add button to create new update with price calculation
    div style: "margin: 20px 0;" do
      link_to "Calculate & Update Shop Item Update",
              user_update_shop_item_update_admin_shop_item_path(shop_item),
              method: :post,
              class: "btn btn-primary",
              style: "background-color: #007cba; color: white; padding: 10px 15px; text-decoration: none; border-radius: 4px;",
              confirm: "This will create a new shop item update with calculated price per unit. Continue?"
    end

    # Display associated shop item updates
    panel "Price & Stock History" do
      table_for shop_item.shop_item_updates.order(created_at: :desc) do
        column :price do |update|
          best_in_place update, :price,
                        as: :input,
                        url: admin_shop_item_update_path(update),
                        placeholder: "Enter price",
                        class: "bip-input-unit",
                        html_attrs: { style: "width: 100px" },
                        display_with: lambda { |value| value.present? ? number_to_currency(value) : "N/A" }
        end
        column :stock_status do |update|
          best_in_place update, :stock_status,
                        as: :input,
                        url: admin_shop_item_update_path(update),
                        placeholder: "Select status",
                        class: "bip-input-unit",
                        html_attrs: { style: "width: 100px" },
                        display_with: lambda { |value| value.present? ? value : "N/A" }
        end
        column :price_per_unit do |update|
          if update&.price_per_unit
            number_to_currency(update.price_per_unit)
          else
            "N/A"
          end
        end
        column :normalized_unit
        column :created_at
      end
    end
  end

  # Add scopes for quick filtering
  scope :all
  scope :approved, -> { where(approved: true) }
  scope :pending_approval, -> { where(approved: false) }
  scope :needs_review, -> { where(needs_another_review: true) }
  scope :missing_shop_item_category, -> { where(shop_item_category_id: nil) }
  scope :missing_shop_item_sub_category, -> { where(shop_item_sub_category_id: nil) }
  scope :was_manually_updated, -> { where(was_manually_updated: true) }
  #scope :amazon, -> { where(shop: 'Amazon') }
  #scope :ebay, -> { where(shop: 'eBay') }
  #scope :etsy, -> { where(shop: 'Etsy') }
  #
  #

  # Add batch actions
  batch_action :approve do |ids|
    ShopItem.where(id: ids).update_all(approved: true)
    redirect_to collection_path, alert: "#{ids.count} shop items have been approved."
  end

  batch_action :reject do |ids|
    ShopItem.where(id: ids).update_all(approved: false)
    redirect_to collection_path, alert: "#{ids.count} shop items have been rejected."
  end

  batch_action :mark_needs_review do |ids|
    ShopItem.where(id: ids).update_all(needs_another_review: true)
    redirect_to collection_path, alert: "#{ids.count} shop items have been marked as needing another review."
  end
  batch_action :unmark_needs_review do |ids|
    ShopItem.where(id: ids).update_all(needs_another_review: false)
    redirect_to collection_path, alert: "#{ids.count} shop items have been unmarked as needing another review."
  end

  batch_action :assign_category, form: {
                                   category_id: ShopItemCategory.all.collect { |c| [c.title, c.id] },
                                 } do |ids|
    #log the params to see what is being passed
    Rails.logger.info "Batch action params: #{params.inspect}"
    batch_inputs = JSON.parse(params[:batch_action_inputs])

    category_id = batch_inputs["category_id"]

    if category_id.present?
      ShopItem.where(id: ids).update_all(shop_item_category_id: category_id, shop_item_sub_category_id: nil)
      category_name = ShopItemCategory.find(category_id).title
      redirect_to collection_path, notice: "#{ids.count} shop items have been assigned to category '#{category_name}'."
    else
      redirect_to collection_path, alert: "Please select a category."
    end
  end

  batch_action :remove_category do |ids|
    ShopItem.where(id: ids).update_all(shop_item_category_id: nil, shop_item_sub_category_id: nil)
    redirect_to collection_path, notice: "Category and sub-category have been removed from #{ids.count} shop items."
  end

  # Alternative: Single batch action that shows sub-categories based on selected items' categories
  batch_action :assign_subcategory_smart, form: proc {
                               # Get all sub-categories grouped by category for the form
                               subcategories_by_category = {}
                               ShopItemCategory.includes(:shop_item_sub_categories).each do |category|
                                 next if category.shop_item_sub_categories.empty?
                                 subcategories_by_category["#{category.title}"] = category.shop_item_sub_categories.collect { |sc| ["#{category.title} > #{sc.title}", sc.id] }
                               end

                               # Flatten all sub-categories into one list
                               all_subcategories = subcategories_by_category.values.flatten(1)

                               {
                                 sub_category_id: all_subcategories,
                               }
                             } do |ids|
    batch_inputs = JSON.parse(params[:batch_action_inputs])
    sub_category_id = batch_inputs["sub_category_id"]

    if sub_category_id.present?
      sub_category = ShopItemSubCategory.find(sub_category_id)

      # Update items to have both the category and sub-category
      ShopItem.where(id: ids).update_all(
        shop_item_category_id: sub_category.shop_item_category_id,
        shop_item_sub_category_id: sub_category_id,
      )

      redirect_to collection_path,
                  notice: "#{ids.count} shop items have been assigned to '#{sub_category.shop_item_category.title}' > '#{sub_category.title}'."
    else
      redirect_to collection_path, alert: "Please select a sub-category."
    end
  end

  # Dynamically create batch actions for each category's sub-categories
  ShopItemCategory.all.each do |category|
    # Skip if category has no sub-categories
    next if category.shop_item_sub_categories.empty?

    # Clean up the category name for the action name
    clean_category_name = category.title.downcase.gsub(/[^a-z0-9]/, "_").gsub(/_+/, "_").gsub(/^_|_$/, "")

    batch_action "assign_#{clean_category_name}_subcategory".to_sym,
                 form: {
                   sub_category_id: category.shop_item_sub_categories.collect { |sc| [sc.title, sc.id] },
                 } do |ids|
      batch_inputs = JSON.parse(params[:batch_action_inputs])
      sub_category_id = batch_inputs["sub_category_id"]

      if sub_category_id.present?
        sub_category = ShopItemSubCategory.find(sub_category_id)

        # Update items to have both the category and sub-category
        ShopItem.where(id: ids).update_all(
          shop_item_category_id: sub_category.shop_item_category_id,
          shop_item_sub_category_id: sub_category_id,
        )

        redirect_to collection_path,
                    notice: "#{ids.count} shop items have been assigned to '#{category.title}' > '#{sub_category.title}'."
      else
        redirect_to collection_path, alert: "Please select a sub-category."
      end
    end
  end

  # Add custom member action for price calculation
  member_action :user_update_shop_item_update, method: :post do
    latest_update = resource.shop_item_updates.order(created_at: :desc).first

    if latest_update&.price.present? && resource.size.present? && resource.unit.present?
      # Check if calculation is possible
      if PricePerUnitCalculator.should_calculate?(latest_update.price, resource.size, resource.unit)
        calculation_result = PricePerUnitCalculator.calculate_value_only(
          latest_update.price,
          resource.size,
          resource.unit
        )

        if calculation_result
          # Create new update with calculated values
          new_update = resource.shop_item_updates.build(
            price: latest_update.price,
            stock_status: latest_update.stock_status || "N/A",
            price_per_unit: calculation_result[:price_per_unit],
            normalized_unit: calculation_result[:normalized_unit],
          )

          if new_update.save
            redirect_to admin_shop_item_path(resource),
                        notice: "New update created"
          else
            redirect_to admin_shop_item_path(resource),
                        alert: "Failed to create update: #{new_update.errors.full_messages.join(", ")}"
          end
        else
          redirect_to admin_shop_item_path(resource),
                      alert: "Price calculation failed"
        end
      else
        redirect_to admin_shop_item_path(resource),
                    alert: "Cannot calculate price per unit. Check if price, size, and unit are valid."
      end
    else
      redirect_to admin_shop_item_path(resource),
                  alert: "Missing required data: latest price, size, or unit"
    end
  end
end
