ActiveAdmin.register ShopItem do
  # Permit parameters for create/update actions
  permit_params :shop, :url, :title, :display_title, :image_url, :size, :unit, :location, :product_id, :approved, :needs_another_review, :shop_item_type_id, :shop_item_type_title
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
    column :type do |shop_item|
      best_in_place shop_item, :shop_item_type_id,
                    as: :select,
                    url: admin_shop_item_path(shop_item),
                    collection: [[nil]] + ShopItemType.all.pluck(:title, :id).map { |title, id| [id, title] }, html_attrs: { style: "cursor: pointer; min-width: 30px;" },
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
      # Add the custom action button alongside View, Edit, Delete
      item "Calculate Price", user_update_shop_item_update_admin_shop_item_path(shop_item),
           method: :post,
           class: "member_link",
           confirm: "This will create a new shop item update with calculated price per unit. Continue?"
    end
  end

  # Configure filters for the index page
  filter :shop
  filter :title
  filter :url
  filter :location
  filter :approved
  filter :needs_another_review
  filter :shop_item_type, as: :select, collection: proc { ShopItemType.all.pluck(:title, :id) }, include_blank: "None"
  filter :created_at

  # Configure the form for create/edit
  form html: { data: { sub_categories: ShopItemSubCategory.joins(:shop_item_category).pluck("shop_item_categories.id", "shop_item_sub_categories.id", "shop_item_sub_categories.title").group_by(&:first).transform_values { |v| v.map { |item| [item[2], item[1]] } }.to_json } } do |f|
    f.inputs "Shop Item Details" do
      f.input :shop, as: :select, collection: Shop::ALLOWED, include_blank: false
      f.input :url, placeholder: "https://example.com/product"
      f.input :title
      f.input :display_title, hint: "Optional: Custom display name for the item"
      f.input :shop_item_type, as: :select, collection: ShopItemType.all.pluck(:title, :id), include_blank: true, input_html: { id: "shop_item_type_select" }
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
      row :shop_item_type do |shop_item|
        #do a link into the category
        if shop_item.shop_item_type.present?
          link_to shop_item.shop_item_type.title, admin_shop_item_type_path(shop_item.shop_item_type)
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
  scope :missing_shop_item_type, -> { where(shop_item_type_id: nil) }
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

  batch_action :assign_type, form: {
                               type_id: [nil] + ShopItemType.all.collect { |c| [c.title, c.id] },
                             } do |ids|
    #log the params to see what is being passed
    Rails.logger.info "Batch action params: #{params.inspect}"
    batch_inputs = JSON.parse(params[:batch_action_inputs])

    type_id = batch_inputs["type_id"]

    if type_id.present?
      ShopItem.where(id: ids).update_all(shop_item_type_id: type_id)
      type_title = ShopItemType.find(type_id).title
      redirect_to collection_path, notice: "#{ids.count} shop items have been assigned to category '#{type_title}'."
    else
      ShopItem.where(id: ids).update_all(shop_item_type_id: nil)
      redirect_to collection_path, notice: "Type has been removed from #{ids.count} shop items."
    end
  end

  batch_action :remove_type do |ids|
    ShopItem.where(id: ids).update_all(shop_item_type_id: nil)
    redirect_to collection_path, notice: "Type has been removed from #{ids.count} shop items."
  end

  # Add this batch action to your existing batch actions
  batch_action :create_and_assign_type, form: {
                                          type_title: :text,
                                        } do |ids, inputs|
    # Parse the inputs from the form
    batch_inputs = JSON.parse(params[:batch_action_inputs])
    type_title = batch_inputs["type_title"]

    if type_title.present? && type_title.strip.length > 0
      begin
        # Create or find the ShopItemType
        shop_item_type = ShopItemType.find_or_create_by!(title: type_title.strip)

        # Assign it to all selected ShopItems
        updated_count = ShopItem.where(id: ids).update_all(shop_item_type_id: shop_item_type.id)

        # Check if this is a newly created type
        if shop_item_type.created_at > 1.minute.ago
          redirect_to collection_path,
                      notice: "Created new type '#{shop_item_type.title}' and assigned it to #{updated_count} shop items."
        else
          redirect_to collection_path,
                      notice: "Assigned existing type '#{shop_item_type.title}' to #{updated_count} shop items."
        end
      rescue ActiveRecord::RecordInvalid => e
        redirect_to collection_path,
                    alert: "Failed to create type: #{e.record.errors.full_messages.join(", ")}"
      rescue => e
        redirect_to collection_path,
                    alert: "An error occurred: #{e.message}"
      end
    else
      redirect_to collection_path,
                  alert: "Please enter a valid type name."
    end
  end

  # Add custom member action for price calculation
  member_action :user_update_shop_item_update, method: :post do
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
