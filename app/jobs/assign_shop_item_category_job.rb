class AssignShopItemCategoryJob < ApplicationJob
  queue_as :default

  # AssignShopItemCategoryJob.perform_now(batch_size: 10)
  # or
  # AssignShopItemCategoryJob.perform_later(batch_size: 10, category_id:10)

  def perform(args)
    batch_size = args[:batch_size] || 10
    category_id = args[:category_id] || nil
    Rails.logger.info 'Starting ShopItem Category assignment job'

    processed_count = 0
    matched_count = 0
    error_count = 0

    if category_id.present?
      Rails.logger.info "Starting ShopItem matching job for category ID #{category_id}"
      shop_items_scope = ShopItem.pending_approval.where(category_id: category_id)
    else
      Rails.logger.info 'Starting ShopItem matching job'
      shop_items_scope = ShopItem.pending_approval
    end

    shop_items_scope.find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |shop_item|
        # Try to find the best matching category
        best_match = FindCategoryForShopItemService.new(shop_item: shop_item).find

        if best_match
          shop_item.update!(category: best_match)
          matched_count += 1
          Rails.logger.info "Assigned '#{best_match.title}' to '#{shop_item.title}'"
        else
          shop_item.update!(category: nil)
          Rails.logger.info "No matching category found for '#{shop_item.title}'"
        end

        processed_count += 1

        # Optional: Sleep briefly to avoid overwhelming the database
        sleep(0.01) if processed_count % 50 == 0
      rescue StandardError => e
        error_count += 1
        Rails.logger.error "Error processing ShopItem #{shop_item.id}: #{e.message}"
      end
    end

    Rails.logger.info "ShopItem Category assignment completed: #{processed_count} processed, #{matched_count} matched, #{error_count} errors"
  end
end
