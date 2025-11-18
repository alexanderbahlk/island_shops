class AssignNewNormalizedUnitToShopItemJob < ApplicationJob
  queue_as :default

  def perform(batch_size: 10)
    Rails.logger.info 'Starting ShopItem Unit Size assignment job'

    processed_count = 0
    error_count = 0

    ShopItem.where(unit: 'oz').find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |shop_item|
        Rails.logger.debug "Processing ShopItem ID #{shop_item.id} - Title: '#{shop_item.title}'"

        latest_update = shop_item.shop_item_updates.order(created_at: :desc).first

        if latest_update&.price.present? && shop_item.size.present? && shop_item.unit.present? && PricePerUnitCalculator.should_calculate?(
          latest_update.price, shop_item.size, shop_item.unit
        )
          calculation_result = PricePerUnitCalculator.calculate_value_only(
            latest_update.price,
            shop_item.size,
            shop_item.unit
          )
          if calculation_result
            # Create new update with calculated values
            new_update = shop_item.shop_item_updates.build(
              price: latest_update.price,
              stock_status: latest_update.stock_status || 'N/A',
              price_per_unit: calculation_result[:price_per_unit],
              normalized_unit: calculation_result[:normalized_unit]
            )
            if new_update.save
              processed_count += 1
              Rails.logger.info "Updated ShopItem ID #{shop_item.id} with new normalized unit '#{calculation_result[:normalized_unit]}'"
            end
          end

        end

        # Optional: Sleep briefly to avoid overwhelming the database
        sleep(0.01) if processed_count % 50 == 0
      rescue StandardError => e
        error_count += 1
        Rails.logger.error "Error processing ShopItem #{shop_item.id}: #{e.message}"
      end
    end

    Rails.logger.info "ShopItem Unit Size assignment completed: #{processed_count} processed, #{error_count} errors"
  end
end
