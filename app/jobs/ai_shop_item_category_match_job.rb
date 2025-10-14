class AiShopItemCategoryMatchJob < ApplicationJob
  queue_as :default
  retry_on StandardError, attempts: 3, wait: :exponentially_longer
  discard_on ActiveRecord::RecordNotFound
  discard_on ActiveRecord::RecordInvalid
  discard_on ArgumentError
  discard_on JSON::ParserError

  def perform(batch_size: 10, similarity_threshold: 0.5)
    require "informers"

    # Load the Informers model
    model = Informers.pipeline("embedding", "sentence-transformers/all-MiniLM-L6-v2")

    # Precompute category embeddings
    categories = Category.products
    category_embeddings = {}
    categories.each do |category|
      # Combine title and synonyms for matching
      matching_context = [category.title, *category.synonyms].join(" ")
      category_embeddings[category.id] = model.call(matching_context) # Use `call` to generate embeddings
    end

    processed_count = 0
    matched_count = 0
    error_count = 0

    # Process ShopItems in batches
    ShopItem.pending_approval.find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |shop_item|
        begin
          # Generate embedding for the ShopItem
          shop_item_text = "#{shop_item.title} #{shop_item.breadcrumb}"
          shop_item_embedding = model.call(shop_item_text) # Use `call` to generate embeddings

          # Compute cosine similarity with all categories
          best_match = nil
          highest_similarity = -1
          category_embeddings.each do |category_id, category_embedding|
            similarity = cosine_similarity(shop_item_embedding, category_embedding)
            if similarity > highest_similarity
              highest_similarity = similarity
              best_match = category_id
            end
          end

          # Assign the best-matching category if similarity is above the threshold
          if best_match
            Rails.logger.info "Found category #{best_match} for ShopItem #{shop_item.title} with similarity #{highest_similarity.round(4)}"
            if highest_similarity >= similarity_threshold
              shop_item.update!(category_id: best_match)
              matched_count += 1
              Rails.logger.info "Assigned category #{best_match} to ShopItem #{shop_item.title}"
            end
          else
            Rails.logger.info "No suitable category found for ShopItem #{shop_item.title} (highest similarity: #{highest_similarity.round(4)})"
          end

          processed_count += 1

          # Optional: Sleep briefly to avoid overwhelming the database
          sleep(1.0) if processed_count % 50 == 0
        rescue => e
          error_count += 1
          Rails.logger.error "Error processing ShopItem #{shop_item.id}: #{e.message}"
        end
      end
    end

    Rails.logger.info "ShopItem Category assignment completed: #{processed_count} processed, #{matched_count} matched, #{error_count} errors"
  end

  private

  # Compute cosine similarity between two vectors
  def cosine_similarity(vec1, vec2)
    dot_product = vec1.zip(vec2).map { |a, b| a * b }.sum
    magnitude1 = Math.sqrt(vec1.map { |x| x ** 2 }.sum)
    magnitude2 = Math.sqrt(vec2.map { |x| x ** 2 }.sum)
    dot_product / (magnitude1 * magnitude2)
  end
end
