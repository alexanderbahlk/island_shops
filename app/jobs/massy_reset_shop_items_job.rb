class MassyResetShopItemsJob < ApplicationJob
  queue_as :default

  def perform(batch_size: 10)
    Rails.logger.info "Starting MassyResetShopItemsJob job"

    unit_size_count = 0
    matched_count = 0
    shop_item_updates_count = 0
    error_count = 0

    ShopItem.pending_approval.by_shop("Massy").find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |shop_item|
        begin

          # Try to find the best matching category
          best_match = ShopItemCategoryMatcher.new(shop_item: shop_item).find_best_match()

          if best_match
            shop_item.update!(category: best_match)
            matched_count += 1
            Rails.logger.info "Assigned '#{best_match.title}' to '#{shop_item.title}'"
          end

          parsed_data = UnitParser.parse_from_title(shop_item.title)
          shop_item.size = parsed_data[:size] if (shop_item.size.blank? || shop_item.size == 0) && parsed_data[:size].present?
          shop_item.unit = parsed_data[:unit] if (shop_item.unit.blank? || shop_item.unit == "N/A") && parsed_data[:unit].present?
          if shop_item.changed?
            shop_item.save!
            unit_size_count += 1
          end

          latest_update = shop_item.shop_item_updates.order(created_at: :desc).first

          # Calculate price_per_unit using the smart calculator
          if PricePerUnitCalculator.should_calculate?(latest_update.price, shop_item.size, shop_item.unit)
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
                shop_item_updates_count += 1
              end
            end
          end

          # Optional: Sleep briefly to avoid overwhelming the database
          sleep(0.01) if matched_count % 50 == 0
        rescue => e
          error_count += 1
          Rails.logger.error "Error processing ShopItem #{shop_item.id}: #{e.message}"
        end
      end
    end
    Rails.logger.info "ShopItem Category assignment: #{matched_count} matched"
    Rails.logger.info "ShopItem Unit/Size parsing: #{unit_size_count} updated"
    Rails.logger.info "ShopItem Updates created: #{shop_item_updates_count} new updates"
  end
end
