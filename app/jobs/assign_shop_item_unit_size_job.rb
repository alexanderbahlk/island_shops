class AssignShopItemUnitSizeJob < ApplicationJob
  queue_as :default

  def perform(batch_size: 10)
    Rails.logger.info "Starting ShopItem Unit Size assignment job"

    processed_count = 0
    matched_count = 0
    error_count = 0

    ShopItem.no_unit_size.find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |shop_item|
        begin
          Rails.logger.debug "Processing ShopItem ID #{shop_item.id} - Title: '#{shop_item.title}'"
          parsed_data = UnitParser.parse_from_title(shop_item.title)
          Rails.logger.debug "  Parsed data: #{parsed_data.inspect}"
          shop_item.size = parsed_data[:size] if (shop_item.size.blank? || shop_item.size == 0) && parsed_data[:size].present?
          shop_item.unit = parsed_data[:unit] if (shop_item.unit.blank? || shop_item.unit == "N/A") && parsed_data[:unit].present?
          if shop_item.changed?
            shop_item.save!
            matched_count += 1
          end
          # Optional: Sleep briefly to avoid overwhelming the database
          sleep(0.01) if processed_count % 50 == 0
        rescue => e
          error_count += 1
          Rails.logger.error "Error processing ShopItem #{shop_item.id}: #{e.message}"
        end
      end
    end

    Rails.logger.info "ShopItem Unit Size assignment completed: #{processed_count} processed, #{matched_count} matched, #{error_count} errors"
  end
end
