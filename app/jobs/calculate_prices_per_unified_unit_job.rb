class CalculatePricesPerUnifiedUnitJob < ApplicationJob
  queue_as :default

  def perform()
    #find all shop items that have a unit and size defined
    shop_items = ShopItem.where.not(unit: [nil, ""]).where.not(size: [nil, 0])
    Rails.logger.info "Calculating prices per unified unit for #{shop_items.count} shop items"
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
            new_update.save
          end
        end
      rescue => e
        Rails.logger.error "Error calculating price for shop item ID #{shop_item.id}: #{e.message}"
      end
    end
  end
end
