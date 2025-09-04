ActiveAdmin.register ShopItemUpdate do
  # Permit parameters for updates
  permit_params :price, :stock_status, :price_per_unit

  # Only allow updates via AJAX (for best_in_place)
  controller do
    def update
      @shop_item_update = ShopItemUpdate.find(params[:id])

      # Handle best_in_place updates
      if params[:shop_item_update] && params[:shop_item_update].keys.size == 1
        field = params[:shop_item_update].keys.first
        value = params[:shop_item_update][field]

        # Convert price fields to proper decimal values
        if ["price", "price_per_unit"].include?(field)
          value = value.to_f if value.present?
        end

        if @shop_item_update.update(field => value)
          # Return formatted value for display
          display_value = case field
            when "price", "price_per_unit"
              value.present? ? helpers.number_to_currency(value) : "N/A"
            else
              value
            end

          render json: { status: "ok", newValue: display_value }
        else
          render json: { status: "error", msg: @shop_item_update.errors.full_messages.join(", ") }
        end
        return
      end

      # Regular form update
      super
    end
  end

  # Prevent index/show pages for this resource (only used for updates)
  config.clear_action_items!

  # Remove from menu
  menu false
end
