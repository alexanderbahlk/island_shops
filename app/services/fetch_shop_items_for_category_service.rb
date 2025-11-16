class FetchShopItemsForCategoryService
  attr_reader :category, :hide_out_of_stock, :limit

  def initialize(category:, hide_out_of_stock: false, limit: 5)
    @category = category
    @hide_out_of_stock = hide_out_of_stock
    @limit = limit
  end

  def fetch_shop_items
    cache_key = "fetch_shop_items/#{category.id}/#{hide_out_of_stock}/#{limit}"
    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      approved_items_with_updates = category.shop_items.approved.includes(:shop_item_updates)

      shop_items = []

      approved_items_with_updates.select do |item|
        if !(hide_out_of_stock && item.latest_stock_status_out_of_stock?)
          latest_shop_item_update = item.latest_shop_item_update
          second_last_shop_item_update = item.second_last_shop_item_update

          shop_item = {
            title: item.display_title.presence || item.title,
            uuid: item.uuid,
            place: item.place&.title || "N/A",
            image_url: item.image_url,
            unit: item.unit || "N/A",
            stock_status: latest_shop_item_update&.normalized_stock_status || "N/A",
            latest_price: latest_shop_item_update&.price ? format("%.2f", latest_shop_item_update.price) : "N/A",
            latest_price_per_normalized_unit: item.latest_price_per_normalized_unit || "N/A",
            latest_price_per_normalized_unit_with_unit: item.latest_price_per_normalized_unit_with_unit,
            latest_price_per_unit_with_unit: item.latest_price_per_unit_with_unit,
            url: item.url,
          }

          if second_last_shop_item_update&.price
            shop_item[:previous_price] = format("%.2f", second_last_shop_item_update.price)
            shop_item[:price_change] = format("%.2f", latest_shop_item_update.price - second_last_shop_item_update.price)
          end

          shop_items << shop_item
        end
      end

      # Sort by latest_price_per_normalized_unit, placing items without a valid price at the end
      shop_items = shop_items.sort_by { |item| item[:latest_price_per_normalized_unit].to_f.nonzero? || Float::INFINITY }
      # Only take the first 'limit' items
      shop_items = shop_items.first(limit)
      shop_items
    end
  end
end
