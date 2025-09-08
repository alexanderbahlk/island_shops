ActiveAdmin.register ShopItem do
  # Permit parameters for create/update actions
  permit_params :shop, :url, :title, :display_title, :image_url, :size, :unit, :location, :product_id, :approved, :needs_another_review, :category_id

  # Add the action at the top level of the resource
  action_item :assign_missing_categories, only: :index do
    link_to "Auto-assign Missing Categories",
            assign_missing_categories_admin_shop_items_path,
            method: :post,
            data: {
              confirm: "This will automatically assign Categories to all items without a category. Continue?",
              disable_with: "Processing...",
            },
            class: "button"
  end

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
    column :latest_price_per_unit do |shop_item|
      if shop_item.latest_price_per_unit != "N/A"
        shop_item.latest_price_per_unit
      else
        content_tag(:span, "N/A", style: "color: red; font-size: 11px;")
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
    column :category do |shop_item|
      best_in_place shop_item, :category_id,
                    as: :select,
                    url: admin_shop_item_path(shop_item),
                    collection: [[nil, "None"]] + Category.products.pluck(:path, :id).map { |path, id| [id, path.split("/").join(" > ")] },
                    html_attrs: { style: "cursor: pointer; min-width: 150px;" },
                    class: "bip-select-unit"
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
    actions do |shop_item|
      item "Calculate Price", user_update_shop_item_update_admin_shop_item_path(shop_item),
           method: :post,
           class: "member_link",
           confirm: "This will create a new shop item update with calculated price per unit. Continue?"
      item "Re-assign Category", auto_assign_category_admin_shop_item_path(shop_item),
           method: :post,
           class: "member_link",
           confirm: "This will find and assign a new category to this item (replacing the current one). Continue?"
    end
  end

  # Configure filters for the index page
  filter :shop
  filter :title
  filter :url
  filter :location
  filter :approved
  filter :needs_another_review
  filter :category, as: :select, collection: proc {
               Category.products.includes(:parent).map do |cat|
                 [cat.breadcrumbs.map(&:title).join(" > "), cat.id]
               end
             }, include_blank: "Any"
  filter :created_at

  # Configure the form for create/edit
  form do |f|
    f.inputs "Shop Item Details" do
      f.input :shop, as: :select, collection: Shop::ALLOWED, include_blank: false
      f.input :url, placeholder: "https://example.com/product"
      f.input :title
      f.input :display_title, hint: "Optional: Custom display name for the item"
      f.input :category, :label => "Product", as: :select, collection: Category.only_products, include_blank: true, input_html: { id: "category_select" }
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
      row :breadcrumb
      row :display_title do |shop_item|
        best_in_place shop_item, :display_title,
                      as: :input,
                      url: admin_shop_item_path(shop_item),
                      placeholder: "Click to edit display_title",
                      class: "bip-input-unit",
                      html_attrs: { style: "width: 200px" }
      end
      row :category do |shop_item|
        if shop_item.category.present?
          breadcrumb = shop_item.category.breadcrumbs.map(&:title).join(" > ")
          link_to breadcrumb, admin_category_path(shop_item.category)
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
      row :latest_price_per_unit do |shop_item|
        shop_item.latest_price_per_unit
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
  scope :missing_category, -> { where(category_id: nil) }
  scope :was_manually_updated, -> { where(was_manually_updated: true) }

  # Update batch actions for categories
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
                                   category_id: Category.products.includes(:parent).map do |cat|
                                     [cat.breadcrumbs.map(&:title).join(" > "), cat.id]
                                   end.unshift(["Remove Category", nil]),
                                 } do |ids, inputs|
    batch_inputs = JSON.parse(params[:batch_action_inputs])
    category_id = batch_inputs["category_id"].presence

    if category_id
      category = Category.find(category_id)
      ShopItem.where(id: ids).update_all(category_id: category_id)
      category_name = category.breadcrumbs.map(&:title).join(" > ")
      redirect_to collection_path, notice: "#{ids.count} shop items assigned to '#{category_name}'."
    else
      ShopItem.where(id: ids).update_all(category_id: nil)
      redirect_to collection_path, notice: "Category removed from #{ids.count} shop items."
    end
  end

  # Add this batch action after the existing batch actions (around line 290):

  batch_action :create_and_assign_category, form: {
                                              category_title: :text,
                                              parent_category_id: Category.where.not(category_type: :product)
                                                                          .includes(:parent)
                                                                          .map do |cat|
                                                # Build breadcrumb manually
                                                parts = []
                                                current = cat
                                                while current
                                                  parts.unshift(current.title)
                                                  current = current.parent
                                                end
                                                breadcrumb = parts.join(" > ")
                                                [breadcrumb, cat.id]
                                              end
                                                                          .unshift(["No Parent (Root Category)", nil]),
                                            } do |ids, inputs|
    batch_inputs = JSON.parse(params[:batch_action_inputs])
    category_title = batch_inputs["category_title"].strip
    parent_category_id = batch_inputs["parent_category_id"].presence

    # Validate inputs
    if category_title.blank?
      redirect_to collection_path, alert: "Category title cannot be blank."
      return
    end

    begin
      # Find parent category if specified
      parent_category = parent_category_id ? Category.find(parent_category_id) : nil

      # Validate parent category depth (can't exceed 3 levels for products)
      if parent_category && parent_category.depth >= 3
        redirect_to collection_path,
                    alert: "Cannot create product category under '#{parent_category.title}' - maximum hierarchy depth exceeded."
        return
      end

      # Check if category with this title already exists under the same parent
      existing_category = Category.find_by(title: category_title, parent: parent_category)

      if existing_category
        # Use existing category
        new_category = existing_category
        action_message = "Used existing category"
      else
        # Create new category
        new_category = Category.create!(
          title: category_title,
          parent: parent_category,
          sort_order: (parent_category&.children&.maximum(:sort_order) || 0) + 1,
        )
        action_message = "Created new category"
      end

      # Ensure the category is a product type (depth 3)
      unless new_category.product?
        redirect_to collection_path,
                    alert: "Category '#{category_title}' is not a product category (must be at depth 3). Current depth: #{new_category.depth}"
        return
      end

      # Assign the category to all selected shop items
      ShopItem.where(id: ids).update_all(category_id: new_category.id)

      # Build breadcrumb for display
      breadcrumb_parts = []
      current = new_category
      while current
        breadcrumb_parts.unshift(current.title)
        current = current.parent
      end
      category_breadcrumb = breadcrumb_parts.join(" > ")

      redirect_to collection_path,
                  notice: "#{action_message} '#{category_breadcrumb}' and assigned it to #{ids.count} shop items."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to collection_path,
                  alert: "Failed to create category: #{e.record.errors.full_messages.join(", ")}"
    rescue ActiveRecord::RecordNotFound
      redirect_to collection_path,
                  alert: "Selected parent category not found."
    rescue => e
      redirect_to collection_path,
                  alert: "An error occurred: #{e.message}"
    end
  end

  # Collection action for auto-assigning categories
  collection_action :assign_missing_categories, method: :post do
    missing_count = ShopItem.missing_category.count

    if missing_count == 0
      redirect_to collection_path, notice: "No items found without category assignments."
      return
    end

    # Enqueue the job
    AssignShopItemCategoryJob.perform_later

    # You can implement auto-assignment logic here or create a job
    redirect_to collection_path,
                notice: "Auto-assignment job started for #{missing_count} items. Check back in a few minutes to see results."
  end

  # Add this after the existing member action (around line 450)
  member_action :auto_assign_category, method: :post do
    begin
      original_category = resource.category

      # Use the category matcher to find the best match
      match_title = resource.breadcrumb.presence || resource.title
      best_match = ShopItemCategoryMatcher.find_best_match(match_title)

      if best_match
        resource.update!(category: best_match)

        # Build success message with breadcrumb
        category_breadcrumb = best_match.breadcrumbs.map(&:title).join(" > ")

        success_message = if original_category
            "Successfully reassigned '#{resource.title}' from '#{original_category.breadcrumbs.map(&:title).join(" > ")}' to '#{category_breadcrumb}'"
          else
            "Successfully assigned '#{resource.title}' to category '#{category_breadcrumb}'"
          end

        # Add similarity score info if available
        if best_match.respond_to?(:sim_score)
          success_message += " (similarity: #{(best_match.sim_score * 100).round(1)}%)"
        end

        redirect_to collection_path, notice: success_message
      else
        redirect_to collection_path,
                    alert: "No suitable category found for '#{resource.title}'. You may need to create a new category or assign manually."
      end
    rescue ActiveRecord::RecordInvalid => e
      redirect_to collection_path,
                  alert: "Failed to assign category to '#{resource.title}': #{e.record.errors.full_messages.join(", ")}"
    rescue => e
      Rails.logger.error "Error auto-assigning category for item #{resource.id}: #{e.message}"
      redirect_to collection_path,
                  alert: "An error occurred while assigning category to '#{resource.title}': #{e.message}"
    end
  end

  # Keep the existing member action
  member_action :user_update_shop_item_update, method: :post do
    # ... existing implementation stays the same ...
    latest_update = resource.shop_item_updates.order(created_at: :desc).first

    # Determine redirect path based on parameter or referer
    redirect_path = case params[:redirect_to]
      when "show"
        admin_shop_item_path(resource)
      when "index"
        collection_path
      else
        # Fallback: check referer to determine where we came from
        if request.referer&.include?("/admin/shop_items") && !request.referer&.include?("/#{resource.id}")
          collection_path
        else
          admin_shop_item_path(resource)
        end
      end

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
            success_message = if redirect_path == collection_path
                "New update created"
              else
                "New update created"
              end

            redirect_to redirect_path, notice: success_message
          else
            error_message = if redirect_path == collection_path
                "Failed to create update for '#{resource.title}': #{new_update.errors.full_messages.join(", ")}"
              else
                "Failed to create update: #{new_update.errors.full_messages.join(", ")}"
              end

            redirect_to redirect_path, alert: error_message
          end
        else
          redirect_to redirect_path, alert: "Price calculation failed#{redirect_path == collection_path ? " for '#{resource.title}'" : ""}"
        end
      else
        redirect_to redirect_path, alert: "Cannot calculate price per unit#{redirect_path == collection_path ? " for '#{resource.title}'" : ""}. Check if price, size, and unit are valid."
      end
    else
      redirect_to redirect_path, alert: "Missing required data#{redirect_path == collection_path ? " for '#{resource.title}'" : ""}: latest price, size, or unit"
    end
  end
end
