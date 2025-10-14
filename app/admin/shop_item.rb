ActiveAdmin.register ShopItem do
  # Permit parameters for create/update actions
  permit_params :url, :title, :display_title, :image_url, :size, :unit, :location_id, :product_id, :approved, :needs_another_review, :category_id

  # Add the action at the top level of the resource
  #
  action_item :ai_category_match, only: :index do
    link_to "AI Category Match",
            ai_category_match_admin_shop_items_path,
            method: :post,
            data: {
              confirm: "This will start an AI job to suggest categories for items without a category. Continue?",
              disable_with: "Starting...",
            },
            class: "button"
  end

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

  action_item :assign_missing_categories, only: :index do
    link_to "Auto-assign Missing Size & Unit",
            assign_missing_size_unit_admin_shop_items_path,
            method: :post,
            data: {
              confirm: "This will automatically assign Size and Unit to all items without a Size and Unit. Continue?",
              disable_with: "Processing...",
            },
            class: "button"
  end

  controller do
    include ActionView::Helpers::NumberHelper

    before_action :store_current_filters, only: [:index]

    def category_collection
      @category_collection ||= [[nil, "None"]] + Category.products.pluck(:path, :id).map { |path, id| [id, path.split("/").join(" > ")] }.sort_by { |id, breadcrumb| breadcrumb }
    end

    def redirect_to_collection_with_filters(message_type, message)
      # Get stored filters from session
      stored_filters = session[:shop_item_filters] || {}

      Rails.logger.debug "Redirecting with stored filters: #{stored_filters.inspect}"

      redirect_to collection_path(stored_filters), message_type => message
    end

    def store_selected_items(ids)
      session[:selected_shop_items] = ids
      Rails.logger.debug "Stored selected items: #{ids.inspect}"
    end

    def c_get_stored_selected_items
      session[:selected_shop_items] || []
    end

    def c_clear_stored_selected_items
      session.delete(:selected_shop_items)
    end

    private

    def store_current_filters
      # Only store if this is a GET request (not batch actions)
      if request.get?
        filters_to_store = {}

        # Store scope
        filters_to_store[:scope] = params[:scope] if params[:scope].present?

        # Store search/filter params
        filters_to_store[:q] = params[:q] if params[:q].present?

        # Store order
        filters_to_store[:order] = params[:order] if params[:order].present?

        # Store per_page
        filters_to_store[:per_page] = params[:per_page] if params[:per_page].present?

        session[:shop_item_filters] = filters_to_store
        Rails.logger.debug "Stored filters in session: #{filters_to_store.inspect}"
      end
    end
  end

  # Configure the index page
  index do
    selectable_column
    id_column
    column :location do |location|
      location&.location || "N/A"
    end
    column :title do |shop_item|
      link_to shop_item.title, shop_item.url, target: "_blank", data: { shop_item_id: shop_item.id }
    end
    column :breadcrumb do |shop_item|
      #find ">" in the breadcrumb
      if shop_item.breadcrumb.present? && shop_item.breadcrumb.include?(">")
        breadcrumbs = shop_item.breadcrumb.split(" > ")
      elsif shop_item.breadcrumb.present? && shop_item.breadcrumb.include?("/")
        breadcrumbs = shop_item.breadcrumb.split("/")
      else
        breadcrumbs = [shop_item.breadcrumb]
      end
      # remove last item if list is longer than 1
      breadcrumbs.pop if breadcrumbs.length > 1
      breadcrumb = breadcrumbs.join(" > ")
      breadcrumb.present? ? breadcrumb : "N/A"
    end
    #column :display_title do |shop_item|
    #  best_in_place shop_item, :display_title,
    #                as: :input,
    #                url: admin_shop_item_path(shop_item),
    #                placeholder: "Click to edit display title",
    #                class: "bip-input-unit",
    #                html_attrs: { style: "width: 200px" }
    #end
    column :image_url do |shop_item|
      if shop_item.image_url.present?
        image_tag shop_item.image_url, size: "50x50", style: "object-fit: cover;"
      end
    end
    column :category do |shop_item|
      best_in_place shop_item, :category_id,
                    as: :select,
                    url: admin_shop_item_path(shop_item),
                    collection: controller.category_collection,
                    html_attrs: { style: "cursor: pointer; min-width: 150px;" },
                    class: "bip-select-unit"
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
                    collection: UnitParser::VALID_UNITS.sort.map { |unit| [unit, unit] },
                    html_attrs: { style: "cursor: pointer; min-width: 30px;" },
                    class: "bip-select-unit"
    end
    column :latest_price_per_normalized_unit_with_unit do |shop_item|
      if shop_item.latest_price_per_normalized_unit_with_unit != "N/A"
        shop_item.latest_price_per_normalized_unit_with_unit
      else
        content_tag(:span, "N/A", style: "color: red; font-size: 11px;")
      end
    end
    column :latest_stock_status do |shop_item|
      shop_item.latest_stock_status
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
      item "Re-assign Category", auto_assign_category_admin_shop_item_path(shop_item),
           method: :post,
           class: "member_link reassign-category-link custom-action-link",
           data: {
             remote: true,
             type: "json",
             shop_item_id: shop_item.id,
           }
      item "Re-assign Unit & Size", auto_assign_unit_size_admin_shop_item_path(shop_item),
           method: :post,
           class: "member_link reassign-unit-size-link custom-action-link",
           data: {
             remote: true,
             type: "json",
             shop_item_id: shop_item.id,
           }
      item "Re-Calculate Price per Unit", user_update_shop_item_update_admin_shop_item_path(shop_item),
           method: :post,
           class: "member_link calculate-price-link custom-action-link",
           data: {
             remote: true,
             type: "json",
             shop_item_id: shop_item.id,
           }
    end
  end

  # Configure filters for the index page
  filter :title
  filter :breadcrumb
  filter :location, as: :select, collection: Location.all, include_blank: "N/A"
  filter :approved
  filter :needs_another_review
  filter :unit, as: :select, collection: UnitParser::VALID_UNITS.sort.map { |unit| [unit, unit] }
  filter :no_price_per_unified_unit, as: :boolean, label: "Missing Price per Unified Unit"
  filter :category, as: :select, collection: proc {
               Category.products.includes(:parent).map do |cat|
                 [cat.breadcrumbs.map(&:title).join(" > "), cat.id]
               end
             }, include_blank: "Any"
  filter :missing_category
  filter :created_at

  # Configure the form for create/edit
  form do |f|
    f.inputs "Shop Item Details" do
      f.input :location, as: :select, collection: Location.all, include_blank: false
      f.input :url, placeholder: "https://example.com/product"
      f.input :title
      f.input :display_title, hint: "Optional: Custom display name for the item"
      f.input :category, :label => "Product", as: :select, collection: Category.only_products, include_blank: true, input_html: { id: "category_select" }
      f.input :image_url, placeholder: "https://example.com/image.jpg"
      f.input :size
      f.input :unit, as: :select, collection: UnitParser::VALID_UNITS.sort.map { |unit| [unit, unit] }, include_blank: false
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
      row :uuid
      row :location
      row :title
      row :breadcrumb
      row :latest_stock_status
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
                      collection: UnitParser::VALID_UNITS.sort.map { |unit| [unit, unit] },
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
      row :latest_price_per_normalized_unit_with_unit do |shop_item|
        shop_item.latest_price_per_normalized_unit_with_unit
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
    store_selected_items(ids)
    ShopItem.where(id: ids).update_all(approved: true)
    redirect_to_collection_with_filters(:notice, "#{ids.count} shop items have been approved.")
  end

  batch_action :reject do |ids|
    store_selected_items(ids)
    ShopItem.where(id: ids).update_all(approved: false)
    redirect_to_collection_with_filters(:notice, "#{ids.count} shop items have been rejected.")
  end

  batch_action :mark_needs_review do |ids|
    store_selected_items(ids)
    ShopItem.where(id: ids).update_all(needs_another_review: true)
    redirect_to_collection_with_filters(:notice, "#{ids.count} shop items have been marked as needing another review.")
  end

  batch_action :unmark_needs_review do |ids|
    store_selected_items(ids)
    ShopItem.where(id: ids).update_all(needs_another_review: false)
    redirect_to_collection_with_filters(:notice, "#{ids.count} shop items have been unmarked as needing another review.")
  end

  batch_action :set_unit, form: -> {
                            {
                              unit: UnitParser::VALID_UNITS.sort.map { |unit| [unit, unit] },
                            }
                          } do |ids, inputs|
    store_selected_items(ids)
    batch_inputs = JSON.parse(params[:batch_action_inputs])
    selected_unit = batch_inputs["unit"].presence

    if selected_unit.blank?
      redirect_to_collection_with_filters(:alert, "Please select a unit.")
      return
    end

    # Validate the unit is in the allowed list
    unless UnitParser::VALID_UNITS.include?(selected_unit)
      redirect_to_collection_with_filters(:alert, "Invalid unit selected: #{selected_unit}")
      return
    end

    begin
      # Update all selected shop items with the new unit
      updated_count = ShopItem.where(id: ids).update_all(unit: selected_unit)

      redirect_to_collection_with_filters(:notice, "Successfully set unit to '#{selected_unit}' for #{updated_count} shop items.")
    rescue => e
      Rails.logger.error "Error setting unit for shop items #{ids}: #{e.message}"
      redirect_to_collection_with_filters(:alert, "An error occurred while setting the unit: #{e.message}")
    end
  end

  batch_action :assign_category, form: -> {
                                   {
                                     category_search: :text,
                                     category_id: Category.products.includes(:parent).map do |cat|
                                       [cat.breadcrumbs.map(&:title).join(" > "), cat.id]
                                     end.sort_by { |breadcrumb, id| breadcrumb }.unshift(["Remove Category", nil]),
                                   }
                                 } do |ids, inputs|
    store_selected_items(ids)
    batch_inputs = JSON.parse(params[:batch_action_inputs])
    category_id = batch_inputs["category_id"].presence
    category_search = batch_inputs["category_search"].presence

    # If search term is provided, try to find category by path or title
    if category_search.present? && category_id.blank?
      # Search by path or title
      found_category = Category.products
        .joins("LEFT JOIN categories parents ON categories.parent_id = parents.id")
        .where(
          "categories.path ILIKE ? OR categories.title ILIKE ? OR categories.path ILIKE ?",
          "%#{category_search}%",
          "%#{category_search}%",
          "%#{category_search.gsub(" ", "%")}%"
        )
        .first

      if found_category
        category_id = found_category.id
      else
        redirect_to_collection_with_filters(:alert, "No category found matching '#{category_search}'. Please try a different search term.")
        return
      end
    end

    if category_id
      category = Category.find(category_id)
      ShopItem.where(id: ids).update_all(category_id: category_id)
      category_name = category.breadcrumbs.map(&:title).join(" > ")
      redirect_to_collection_with_filters(:notice, "#{ids.count} shop items assigned to '#{category_name}'.")
    else
      ShopItem.where(id: ids).update_all(category_id: nil)
      redirect_to_collection_with_filters(:notice, "Category removed from #{ids.count} shop items.")
    end
  end

  batch_action :calculate_prices_per_unified_unit do |ids|
    store_selected_items(ids)
    # Enqueue the job with selected shop item IDs
    CalculatePricesPerUnifiedUnitJob.perform_later(ids)

    redirect_to_collection_with_filters(:notice, "Price calculation job started for #{ids.count} shop items. Check back in a few minutes to see results.")
  end

  batch_action :create_and_assign_category, form: -> {
                                              {
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
                                                end.unshift(["No Parent (Root Category)", nil]),
                                              }
                                            } do |ids, inputs|
    store_selected_items(ids)
    batch_inputs = JSON.parse(params[:batch_action_inputs])
    category_title = batch_inputs["category_title"].strip
    parent_category_id = batch_inputs["parent_category_id"].presence

    # Validate inputs
    if category_title.blank?
      redirect_to_collection_with_filters(:alert, "Category title cannot be blank.")
      return
    end

    begin
      # Find parent category if specified
      parent_category = parent_category_id ? Category.find(parent_category_id) : nil

      # Validate parent category depth (can't exceed 3 levels for products)
      if parent_category && parent_category.depth >= 3
        redirect_to_collection_with_filters(:alert, "Cannot create product category under '#{parent_category.title}' - maximum hierarchy depth exceeded.")
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
        redirect_to_collection_with_filters(:alert, "Category '#{category_title}' is not a product category (must be at depth 3). Current depth: #{new_category.depth}")
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

      redirect_to_collection_with_filters(:notice, "#{action_message} '#{category_breadcrumb}' and assigned it to #{ids.count} shop items.")
    rescue ActiveRecord::RecordInvalid => e
      redirect_to_collection_with_filters(:alert, "Failed to create category: #{e.record.errors.full_messages.join(", ")}")
    rescue ActiveRecord::RecordNotFound
      redirect_to_collection_with_filters(:alert, "Selected parent category not found.")
    rescue => e
      redirect_to_collection_with_filters(:alert, "An error occurred: #{e.message}")
    end
  end

  # Placeholder for AI category match action
  collection_action :ai_category_match, method: :post do
    # Enqueue the job
    AiShopItemCategoryMatchJob.perform_later

    redirect_to_collection_with_filters(:notice, "AI category matching job started. Check back in a few minutes to see results.")
  end

  # Collection action for auto-assigning categories
  collection_action :assign_missing_categories, method: :post do
    missing_count = ShopItem.missing_category.count

    if missing_count == 0
      redirect_to_collection_with_filters(:notice, "No items found without category assignments.")
      return
    end

    # Enqueue the job
    AssignShopItemCategoryJob.perform_later

    # You can implement auto-assignment logic here or create a job
    redirect_to_collection_with_filters(:notice, "Auto-assignment job started for #{missing_count} items. Check back in a few minutes to see results.")
  end

  # Collection action for auto-assigning categories
  collection_action :assign_missing_size_unit, method: :post do
    missing_count = ShopItem.no_unit_size.count

    if missing_count == 0
      redirect_to_collection_with_filters(:notice, "No items found without category assignments.")
      return
    end

    # Enqueue the job
    AssignShopItemUnitSizeJob.perform_later

    # You can implement auto-assignment logic here or create a job
    redirect_to_collection_with_filters(:notice, "Auto-assignment job started for #{missing_count} items. Check back in a few minutes to see results.")
  end

  # Add collection action for category autocomplete
  collection_action :category_autocomplete, method: :get do
    term = params[:term].to_s.strip

    if term.length >= 2
      categories = Category.products
        .includes(:parent)
        .where(
          "categories.path ILIKE ? OR categories.title ILIKE ?",
          "%#{term}%",
          "%#{term}%"
        )
        .limit(20)
        .map do |cat|
        {
          id: cat.id,
          label: cat.breadcrumbs.map(&:title).join(" > "),
          value: cat.breadcrumbs.map(&:title).join(" > "),
          path: cat.path,
        }
      end

      render json: categories
    else
      render json: []
    end
  end

  # Collection action to get stored selected items
  collection_action :get_stored_selected_items, method: :get do
    selected_items = c_get_stored_selected_items
    render json: { selected_items: selected_items }
  end

  # Collection action to clear stored selected items
  collection_action :clear_stored_selected_items, method: :post do
    c_clear_stored_selected_items
    render json: { status: "success" }
  end

  member_action :auto_assign_unit_size, method: :post do
    parsed_data = UnitParser.parse_from_title(resource.title)
    Rails.logger.debug "Parsed data for item #{resource.id} - Title: '#{resource.title}' => Size: #{parsed_data[:size]}, Unit: #{parsed_data[:unit]}"
    resource.size = parsed_data[:size] if (resource.size.blank? || resource.size == 0) && parsed_data[:size].present?
    resource.unit = parsed_data[:unit] if (resource.unit.blank? || resource.unit == "N/A") && parsed_data[:unit].present?
    if resource.changed?
      resource.save!
      success_message = "Successfully updated '#{resource.title}'"
      success_message += " with size: #{resource.size}" if parsed_data[:size].present?
      success_message += " and unit: #{resource.unit}" if parsed_data[:unit].present?

      respond_to do |format|
        format.html { redirect_to_collection_with_filters(:notice, success_message) }
        format.json {
          render json: {
            status: "success",
            message: success_message,
            shop_item_id: resource.id,
            size: resource.size,
            unit: resource.unit,
          }
        }
      end
    else
      error_message = "No changes made to '#{resource.title}'. It may already have size and unit assigned."

      respond_to do |format|
        format.html { redirect_to_collection_with_filters(:alert, error_message) }
        format.json { render json: { status: "error", message: error_message, shop_item_id: resource.id } }
      end
    end
  end

  member_action :auto_assign_category, method: :post do
    begin
      original_category = resource.category

      # Use the category matcher to find the best match
      best_match = ShopItemCategoryMatcher.new(shop_item: resource).find_best_match()

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

        respond_to do |format|
          format.html { redirect_to_collection_with_filters(:notice, success_message) }
          format.json {
            render json: {
              status: "success",
              message: success_message,
              category_id: best_match.id,
              category_breadcrumb: category_breadcrumb,
              shop_item_id: resource.id,
            }
          }
        end
      else
        error_message = "No suitable category found for '#{resource.title}'. You may need to create a new category or assign manually."

        respond_to do |format|
          format.html { redirect_to_collection_with_filters(:alert, error_message) }
          format.json {
            render json: {
              status: "error",
              message: error_message,
              shop_item_id: resource.id,
            }
          }
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      error_message = "Failed to assign category to '#{resource.title}': #{e.record.errors.full_messages.join(", ")}"

      respond_to do |format|
        format.html { redirect_to_collection_with_filters(:alert, error_message) }
        format.json { render json: { status: "error", message: error_message, shop_item_id: resource.id } }
      end
    rescue => e
      Rails.logger.error "Error auto-assigning category for item #{resource.id}: #{e.message}"
      error_message = "An error occurred while assigning category to '#{resource.title}': #{e.message}"

      respond_to do |format|
        format.html { redirect_to_collection_with_filters(:alert, error_message) }
        format.json { render json: { status: "error", message: error_message, shop_item_id: resource.id } }
      end
    end
  end

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
            # Use view_context to access helper methods
            formatted_price = view_context.number_to_currency(calculation_result[:price_per_unit])
            success_message = "New update created with price per unit: #{formatted_price} per #{calculation_result[:normalized_unit]}"

            respond_to do |format|
              format.html {
                stored_filters = session[:shop_item_filters] || {}
                redirect_to collection_path(stored_filters), notice: success_message
              }
              format.json {
                render json: {
                  status: "success",
                  message: success_message,
                  shop_item_id: resource.id,
                  price_per_unit: number_to_currency(calculation_result[:price_per_unit]),
                  normalized_unit: calculation_result[:normalized_unit],
                  latest_price_per_normalized_unit_with_unit: resource.reload.latest_price_per_normalized_unit_with_unit,
                }
              }
            end
          else
            error_message = "Failed to create update for '#{resource.title}': #{new_update.errors.full_messages.join(", ")}"

            respond_to do |format|
              format.html {
                stored_filters = session[:shop_item_filters] || {}
                redirect_to collection_path(stored_filters), alert: error_message
              }
              format.json { render json: { status: "error", message: error_message, shop_item_id: resource.id } }
            end
          end
        else
          error_message = "Price calculation failed for '#{resource.title}'"

          respond_to do |format|
            format.html {
              stored_filters = session[:shop_item_filters] || {}
              redirect_to collection_path(stored_filters), alert: error_message
            }
            format.json { render json: { status: "error", message: error_message, shop_item_id: resource.id } }
          end
        end
      else
        error_message = "Cannot calculate price per unit for '#{resource.title}'. Check if price, size, and unit are valid."

        respond_to do |format|
          format.html {
            stored_filters = session[:shop_item_filters] || {}
            redirect_to collection_path(stored_filters), alert: error_message
          }
          format.json { render json: { status: "error", message: error_message, shop_item_id: resource.id } }
        end
      end
    else
      error_message = "Missing required data for '#{resource.title}': latest price, size, or unit"

      respond_to do |format|
        format.html {
          stored_filters = session[:shop_item_filters] || {}
          redirect_to collection_path(stored_filters), alert: error_message
        }
        format.json { render json: { status: "error", message: error_message, shop_item_id: resource.id } }
      end
    end
  end
end
