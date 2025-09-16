class CategoryShopItemSearch
  SIMILARITY_THRESHOLD = 0.4

  attr_reader :query, :hide_out_of_stock, :limit

  def initialize(query:, hide_out_of_stock: false, limit: 5)
    @query = query&.strip
    @hide_out_of_stock = hide_out_of_stock
    @limit = limit
  end

  def results
    return [] if query.blank? || query.length < 2

    categories = find_similar_categories
    categories.map do |category|
      shop_items = fetch_shop_items(category)
      {
        title: category.title,
        breadcrumb: build_breadcrumb(category),
        path: category.path,
        shop_items: shop_items,
      }
    end.sort_by { |cat| -cat[:shop_items].size }
  end

  private

  def find_similar_categories
    return [] unless ShopItemCategoryMatcher.send(:pg_trgm_available?)

    sanitized_query = ActiveRecord::Base.connection.quote(query.downcase)
    sql = <<~SQL
      SELECT categories.*,
             GREATEST(
               similarity(categories.title, #{sanitized_query}),
               similarity(categories.path, #{sanitized_query}),
               COALESCE((
                 SELECT MAX(similarity(syn, #{sanitized_query}))
                 FROM unnest(categories.synonyms) AS syn
               ), 0)
             ) as sim_score
      FROM categories
      WHERE category_type = #{Category.category_types[:product]}
        AND (
          similarity(categories.title, #{sanitized_query}) > #{SIMILARITY_THRESHOLD}
          OR similarity(categories.path, #{sanitized_query}) > #{SIMILARITY_THRESHOLD}
          OR EXISTS (
            SELECT 1 FROM unnest(categories.synonyms) AS syn
            WHERE similarity(syn, #{sanitized_query}) > #{SIMILARITY_THRESHOLD}
          )
        )
      ORDER BY sim_score DESC
      LIMIT #{limit.to_i}
    SQL

    results = ActiveRecord::Base.connection.exec_query(sql)
    category_ids = results.map { |result| result["id"] }
    categories = Category.where(id: category_ids).includes(:shop_items, :parent)
    results.map do |result|
      category = categories.find { |c| c.id == result["id"].to_i }
      if category
        category.define_singleton_method(:sim_score) { result["sim_score"].to_f }
        category
      end
    end.compact
  end

  def fetch_shop_items(category)
    items = category.shop_items.approved.includes(:shop_item_updates)
    items = items.select do |item|
      latest_update = item.shop_item_updates.order(created_at: :desc).first
      !(hide_out_of_stock && (!latest_update || latest_update.out_of_stock?))
    end

    items = items.sort_by { |item| item.latest_price_per_unified_unit || Float::INFINITY }
    items.first(limit).map do |item|
      latest_update = item.shop_item_updates.order(created_at: :desc).first
      {
        title: item.display_title.presence || item.title,
        shop: item.shop,
        image_url: item.image_url,
        unit: item.unit || "N/A",
        stock_status: latest_update&.normalized_stock_status || "N/A",
        latest_price: latest_update&.price || "N/A",
        latest_price_per_unified_unit: item.latest_price_per_unified_unit,
        latest_price_per_unit: item.latest_price_per_unit,
        url: item.url,
      }
    end
  end

  def build_breadcrumb(category)
    breadcrumb_parts = []
    current_category = category
    while current_category
      breadcrumb_parts.unshift(current_category.title)
      current_category = current_category.parent
    end
    breadcrumb_parts.pop
    breadcrumb_parts
  rescue
    [category.title]
  end
end
