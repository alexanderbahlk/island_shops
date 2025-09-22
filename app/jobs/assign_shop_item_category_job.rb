class AssignShopItemCategoryJob < ApplicationJob
  queue_as :default

  def perform(batch_size: 10)
    Rails.logger.info "Starting ShopItem Category assignment job"

    processed_count = 0
    matched_count = 0
    error_count = 0

    ShopItem.missing_category.find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |shop_item|
        begin
          # Try to find the best matching category
          best_match = ShopItemCategoryMatcher.new(shop_item: shop_item).find_best_match()

          if best_match
            shop_item.update!(category: best_match)
            matched_count += 1
            Rails.logger.info "Assigned '#{best_match.title}' to '#{match_title}'"
          end

          processed_count += 1

          # Optional: Sleep briefly to avoid overwhelming the database
          sleep(0.01) if processed_count % 50 == 0
        rescue => e
          error_count += 1
          Rails.logger.error "Error processing ShopItem #{shop_item.id}: #{e.message}"
        end
      end
    end

    Rails.logger.info "ShopItem Category assignment completed: #{processed_count} processed, #{matched_count} matched, #{error_count} errors"
  end
end
