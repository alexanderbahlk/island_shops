class CalculatePricesPerUnifiedUnitJob < ApplicationJob
  queue_as :default

  def perform(shop_item_ids = nil)
    if shop_item_ids.present?
      # Process specific shop items
      shop_items = ShopItem.where(id: shop_item_ids)
        .where.not(unit: [nil, ""])
        .where.not(size: [nil, 0])
      Rails.logger.info "Calculating prices per unified unit for #{shop_items.count} selected shop items"
    else
      # Process all shop items (original behavior)
      shop_items = ShopItem.where.not(unit: [nil, ""])
        .where.not(size: [nil, 0])
      Rails.logger.info "Calculating prices per unified unit for #{shop_items.count} shop items"
    end

    processed_count = 0
    error_count = 0

    shop_items.find_each(batch_size: 100) do |shop_item|
      begin
        latest_update = shop_item.shop_item_updates.order(created_at: :desc).first

        if latest_update.nil? || latest_update.price.nil?
          Rails.logger.info "Skipping shop item ID #{shop_item.id} - no price available"
          next
        end

        if PricePerUnitCalculator.should_calculate?(latest_update.price, shop_item.size, shop_item.unit)
          Rails.logger.info "Calculating price for shop item ID #{shop_item.id}"

          calculation_result = PricePerUnitCalculator.calculate_value_only(
            latest_update.price,
            shop_item.size,
            shop_item.unit
          )

          if calculation_result
            new_update = shop_item.shop_item_updates.build(
              price: latest_update.price,
              stock_status: latest_update.stock_status || "N/A",
              price_per_unit: calculation_result[:price_per_unit],
              normalized_unit: calculation_result[:normalized_unit],
            )

            if new_update.save
              processed_count += 1
              Rails.logger.info "Successfully created price update for shop item ID #{shop_item.id}"
            else
              error_count += 1
              Rails.logger.error "Failed to save price update for shop item ID #{shop_item.id}: #{new_update.errors.full_messages.join(", ")}"
            end
          else
            Rails.logger.warn "Price calculation returned nil for shop item ID #{shop_item.id}"
          end
        else
          Rails.logger.info "Skipping shop item ID #{shop_item.id} - calculation not needed or invalid data"
        end
      rescue => e
        error_count += 1
        Rails.logger.error "Error calculating price for shop item ID #{shop_item.id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end

    completion_message = if shop_item_ids.present?
        "Price calculation completed for selected items. Processed: #{processed_count}, Errors: #{error_count}"
      else
        "Price calculation completed for all items. Processed: #{processed_count}, Errors: #{error_count}"
      end

    Rails.logger.info completion_message
  end
end
