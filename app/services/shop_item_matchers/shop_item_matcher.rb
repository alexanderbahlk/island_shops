class ShopItemMatchers::ShopItemMatcher
  include PgSearchChecker
  include TitleNormalizer

  def initialize(title:, sim:)
    @title = title
    @similarity_threshold = sim
  end

  def find_best_match
    if @title.blank?
      Rails.logger.warn 'No title provided for shop item matching.'
      return nil
    end

    return nil unless pg_trgm_available?

    found_shop_item = find_shop_item_by_title(@title)

    return found_shop_item if found_shop_item.present?

    nil
  end

  private

  def find_shop_item_by_title(title)
    # Clean and normalize the title
    normalized_title = normalize_title(title)
    sanitized_shop_item_title = ActiveRecord::Base.connection.quote(normalized_title)
    find_fuzzy_match(sanitized_shop_item_title, @similarity_threshold)
  end

  def find_fuzzy_match(sanitized_shop_item_title, similarity_threshold)
    results = sql_without_breadcrumb(sanitized_shop_item_title, similarity_threshold)

    return nil if results.empty?

    # make results into array of hashes
    results_array = results.to_a
    # latest_price_per_normalized_unit_with_unit to each entry
    results_array.each do |item|
      item['latest_price_per_normalized_unit_with_unit'] = if item['price_per_unit'].present? && item['normalized_unit'].present?
                                                             '$' + format('%.2f', item['price_per_unit']).to_s + ' per ' + item['normalized_unit'].to_s
                                                           else
                                                             'N/A'
                                                           end
    end
    Rails.logger.debug("Fuzzy match results for '#{@title}': #{results_array.inspect}")
    results_array
  rescue StandardError => e
    Rails.logger.error "Error in find_fuzzy_match: #{e.message}"
    nil
  end

  def sql_without_breadcrumb(sanitized_shop_item_title, similarity_threshold)
    cache_key = "fuzzy_match_shop_item_by_title/#{sanitized_shop_item_title}_#{similarity_threshold}"
    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      sql = <<~SQL
        SELECT shop_items.uuid, shop_items.title, shop_items.image_url, shop_items.unit, shop_items.size, shop_items.url,
               shop_item_updates.price_per_unit, shop_item_updates.normalized_unit, shop_item_updates.price,
               places.title as place_title,
               GREATEST(
                 similarity(shop_items.title, #{sanitized_shop_item_title})
               ) as sim_score
        FROM shop_items
        JOIN shop_item_updates ON shop_item_updates.id = (
          SELECT id FROM shop_item_updates
          WHERE shop_item_updates.shop_item_id = shop_items.id
          ORDER BY shop_item_updates.created_at DESC, shop_item_updates.id DESC
          LIMIT 1
        )
        JOIN places ON places.id = (
          SELECT id FROM places
          WHERE shop_items.place_id = places.id
          ORDER BY places.created_at DESC, places.id DESC
          LIMIT 1
        )
        WHERE similarity(shop_items.title, #{sanitized_shop_item_title}) > #{similarity_threshold}
        ORDER BY sim_score DESC
        LIMIT 10
      SQL
      ActiveRecord::Base.connection.exec_query(sql)
    end
  end
end
