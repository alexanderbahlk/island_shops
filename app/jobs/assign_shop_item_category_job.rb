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
          match_title = @shop_item.breadcrumb.presence || shop_item.title
          best_match = ShopItemCategoryMatcher.find_best_match(match_title)

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

    # Store results for later retrieval (optional)
    Rails.cache.write(
      "shop_item_category_assignment_results",
      {
        processed: processed_count,
        matched: matched_count,
        errors: error_count,
        completed_at: Time.current,
      },
      expires_in: 1.hour,
    )
  end
end
