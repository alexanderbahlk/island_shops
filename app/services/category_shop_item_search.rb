class CategoryShopItemSearch
  include PgSearchChecker
  include CategoryBreadcrumbHelper
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
      fetcher = FetchShopItemsForCategoryService.new(category: category)
      shop_items = fetcher.fetch_shop_items
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
    return [] unless pg_trgm_available?

    Rails.cache.fetch("find_similar_categories/#{query}/#{limit}", expires_in: 5.minutes) do
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
  end
end
