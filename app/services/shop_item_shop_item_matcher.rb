class ShopItemShopItemMatcher
  include PgSearchChecker
  include TitleNormalizer

  SIMILARITY_THRESHOLD = 0.60 # Adjust this value between 0.0 and 1.0

  def initialize(shop_item:, sim: SIMILARITY_THRESHOLD)
    @shop_item = shop_item
    @similarity_threshold = sim
  end

  def find_best_match()
    if @shop_item.blank?
      Rails.logger.warn "No shop item provided for shop item matching."
      return nil
    end

    return nil unless pg_trgm_available?

    found_category = find_category_by_title(@shop_item.title)

    if found_category.present?
      return found_category
    else
      return nil
    end
  end

  private

  def find_category_by_title(title)
    # Clean and normalize the title
    normalized_title = normalize_title(title)
    sanitized_shop_item_title = ActiveRecord::Base.connection.quote(normalized_title)
    result = find_fuzzy_match(sanitized_shop_item_title, true, @similarity_threshold)
    if result.nil?
      result = find_fuzzy_match(sanitized_shop_item_title, false, @similarity_threshold + 0.2)
    end
    return result
  end

  def find_fuzzy_match(sanitized_shop_item_title, same_place_and_breadcrumb, similarity_threshold)
    begin
      results = if same_place_and_breadcrumb && @shop_item.place.present? && @shop_item.breadcrumb.present?
          sql_with_same_place_and_breadcrumb(sanitized_shop_item_title, similarity_threshold)
        else
          sql_without_breadcrumb(sanitized_shop_item_title, similarity_threshold)
        end

      return nil if results.empty?

      # Convert the first result back to a ShopItem object
      first_result = results.first
      shop_item = ShopItem.find(first_result["id"])
      return nil if shop_item.category.nil?
      category = shop_item.category
      category.define_singleton_method(:sim_score) { first_result["sim_score"].to_f }
      category
    rescue => e
      Rails.logger.error "Error in find_fuzzy_match: #{e.message}"
      nil
    end
  end

  def sql_without_breadcrumb(sanitized_shop_item_title, similarity_threshold)
    sql = <<~SQL
      SELECT shop_items.*,
             GREATEST(
               similarity(shop_items.title, #{sanitized_shop_item_title})
             ) as sim_score
      FROM shop_items
      WHERE approved = true
      AND similarity(shop_items.title, #{sanitized_shop_item_title}) > #{similarity_threshold}
      ORDER BY sim_score DESC
      LIMIT 1
    SQL
    results = ActiveRecord::Base.connection.exec_query(sql)
    results
  end

  def sql_with_same_place_and_breadcrumb(sanitized_shop_item_title, similarity_threshold)
    sanitized_place_id = ActiveRecord::Base.connection.quote(@shop_item.place.id)
    sanitized_breadcrumb = ActiveRecord::Base.connection.quote(@shop_item.breadcrumb)

    sql = <<~SQL
      SELECT shop_items.*,
             GREATEST(
               similarity(shop_items.title, #{sanitized_shop_item_title})
             ) as sim_score
      FROM shop_items
      WHERE shop_items.approved = true
        AND shop_items.place_id IS NOT NULL
        AND shop_items.breadcrumb IS NOT NULL
        AND shop_items.place_id = #{sanitized_place_id}
        AND shop_items.breadcrumb = #{sanitized_breadcrumb}
        AND similarity(shop_items.title, #{sanitized_shop_item_title}) > #{similarity_threshold}
      ORDER BY sim_score DESC
      LIMIT 1
    SQL

    results = ActiveRecord::Base.connection.exec_query(sql)
    results
  end
end
