class ShopItemModelEmbeddingsUpdateJob < ApplicationJob
  queue_as :default
  retry_on StandardError, attempts: 3, wait: :exponentially_longer
  discard_on ActiveRecord::RecordNotFound
  discard_on ActiveRecord::RecordInvalid
  discard_on ArgumentError

  def perform(batch_size: 10)
    require "informers"

    # Load the Informers model
    model = Informers.pipeline("embedding", "sentence-transformers/all-MiniLM-L6-v2")

    to_process = ShopItem.needs_model_embedding_update.count
    Rails.logger.info "Starting ShopItem model embedding update job. #{to_process} items to process."
    processed_count = 0
    error_count = 0

    # Process ShopItems in batches
    ShopItem.needs_model_embedding_update.find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |shop_item|
        begin
          # Generate embedding for the ShopItem
          shop_item_text = "#{shop_item.title} #{shop_item.breadcrumb}"
          shop_item_embedding = model.call(shop_item_text) # Use `call` to generate embeddings

          shop_item.update!(model_embedding: shop_item_embedding, needs_model_embedding_update: false)

          processed_count += 1

          Rails.logger.info "Updated model embedding for ShopItem #{shop_item.id} (#{shop_item.title})"
          Rails.logger.info "Progress: #{processed_count}/#{to_process} items processed"

          # Optional: Sleep briefly to avoid overwhelming the database
          sleep(0.2)
        rescue => e
          error_count += 1
          Rails.logger.error "Error processing ShopItem #{shop_item.id}: #{e.message}"
        end
      end
    end
    Rails.logger.info "ShopItem Category assignment completed: #{processed_count} processed, #{error_count} errors"

    #how to clean the memory afterwards
    model = nil
    GC.start
    sleep(1)
  end
end
