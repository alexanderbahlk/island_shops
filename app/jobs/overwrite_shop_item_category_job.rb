class OverwriteShopItemCategoryJob < ApplicationJob
  queue_as :default

  #OverwriteShopItemCategoryJob.perform_now(old_category_id: 1, similarity_threshold: 0.4)

  def perform(args)
    old_category_id = args[:old_category_id]
    similarity_threshold = args[:similarity_threshold]
    batch_size = args[:batch_size] || 10
    Rails.logger.info "Starting Overwrite ShopItem Category job for category ID #{old_category_id}"

    #throw error if old_category_id.nil?
    if old_category_id.nil?
      Rails.logger.error "Old category ID is nil"
      return
    end

    if similarity_threshold.nil?
      Rails.logger.error "Similarity threshold is nil"
      return
    end

    processed_count = 0
    matched_count = 0
    error_count = 0

    ShopItem.where(category_id: old_category_id).find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |shop_item|
        begin
          # Try to find the best matching category
          best_match = ShopItemCategoryMatcher.new(shop_item: shop_item, sim: similarity_threshold).find_best_match()

          if best_match
            shop_item.update!(category: best_match, approved: false)
            matched_count += 1
            Rails.logger.info "Assigned '#{best_match.title}' to '#{shop_item.title}'"
          else
            shop_item.update!(category: nil, approved: false)
            Rails.logger.info "No suitable category found for '#{shop_item.title}', category set to nil"
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
