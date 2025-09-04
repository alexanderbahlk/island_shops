ActiveAdmin.register ShopItem do
  # Permit parameters for create/update actions
  permit_params :shop, :url, :title, :display_title, :image_url, :size, :unit, :location, :product_id, :approved

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
    column :approved
    column :created_at
    actions
  end

  # Configure filters for the index page
  filter :shop
  filter :title
  filter :url
  filter :location
  filter :approved
  filter :created_at

  # Configure the form for create/edit
  form do |f|
    f.inputs "Shop Item Details" do
      f.input :shop, as: :select, collection: Shop::ALLOWED, include_blank: false
      f.input :url, placeholder: "https://example.com/product"
      f.input :title
      f.input :display_title, hint: "Optional: Custom display name for the item"
      f.input :image_url, placeholder: "https://example.com/image.jpg"
      f.input :size
      f.input :unit
      f.input :location
      f.input :product_id
      f.input :approved, as: :boolean
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
      row :url do |shop_item|
        link_to shop_item.url, shop_item.url, target: '_blank' if shop_item.url.present?
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
end