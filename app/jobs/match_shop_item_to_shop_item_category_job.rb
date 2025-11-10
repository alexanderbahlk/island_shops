class MatchShopItemToShopItemCategoryJob < ApplicationJob
  queue_as :default

  #MatchShopItemToShopItemCategoryJob.perform_now(similarity_threshold: 0.6, batch_size: 10)
  #or
  #MatchShopItemToShopItemCategoryJob.perform_later(similarity_threshold: 0.6, batch_size: 10, category_id:10)

  def perform(args)
    category_id = args[:category_id]
    similarity_threshold = args[:similarity_threshold]
    batch_size = args[:batch_size] || 10

    processed_count = 0
    matched_count = 0
    error_count = 0

    if category_id.present?
      Rails.logger.info "Starting ShopItem matching job for category ID #{category_id}"
      shop_items_scope = ShopItem.pending_approval.where(category_id: category_id)
    else
      Rails.logger.info "Starting ShopItem matching job"
      shop_items_scope = ShopItem.pending_approval
    end

    shop_items_scope.find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |shop_item|
        begin
          # Try to find the best matching category
          best_match = ShopItemShopItemMatcher.new(shop_item: shop_item, sim: similarity_threshold).find_best_match()

          if best_match.nil?
            best_match = ShopItemCategoryMatcher.new(shop_item: shop_item, sim: similarity_threshold).find_best_match()
          end

          if best_match
            shop_item.update!(category: best_match)
            matched_count += 1
            Rails.logger.info "Assigned '#{best_match.title}' to '#{shop_item.title}'"
          else
            shop_item.update!(category: nil)
            Rails.logger.info "No matching Shop Item found for '#{shop_item.title}'"
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

    Rails.logger.info "ShopItem matching completed: #{processed_count} processed, #{matched_count} matched, #{error_count} errors"
  end
end
