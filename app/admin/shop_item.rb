ActiveAdmin.register ShopItem do
  # Permit parameters for create/update actions
  permit_params :shop, :url, :title, :display_title, :image_url, :size, :unit, :location, :product_id, :approved, :needs_another_review, :shop_item_category_id, :shop_item_sub_category_id

  # Configure the index page
  index do
    selectable_column
    id_column
    column :shop
    column :title
    column :display_title
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
    column :size
    column :unit
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
    column :approved
    column :needs_another_review
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
      f.input :unit
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
      row :display_title
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
      row :size
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
      row :approved
      row :needs_another_review
      row :created_at
      row :updated_at
    end

    # Display associated shop item updates
    panel "Price & Stock History" do
      table_for shop_item.shop_item_updates.order(created_at: :desc) do
        column :price do |update|
          number_to_currency(update.price) if update.price
        end
        column :stock_status
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
  #scope :amazon, -> { where(shop: 'Amazon') }
  #scope :ebay, -> { where(shop: 'eBay') }
  #scope :etsy, -> { where(shop: 'Etsy') }

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
end
