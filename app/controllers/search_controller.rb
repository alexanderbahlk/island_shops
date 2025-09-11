class SearchController < ApplicationController
  def index
    @initial_query = params[:q]&.strip
  end

  def categories
    query = params[:q]&.strip

    if query.blank? || query.length < 2
      render json: []
      return
    end

    # Use the existing fuzzy matching logic from ShopItemCategoryMatcher
    categories = find_similar_categories(query)
    Rails.logger.info "Found #{categories.size} similar categories for query '#{query}'"

    # Build the formatted response
    formatted_categories = categories.map do |category|
      Rails.logger.info "Processing category: #{category.title}, ID: #{category.id}"

      # Fetch shop items for this category
      shop_items = category.shop_items.approved.limit(5).includes(:shop_item_updates)
      Rails.logger.info "  Found #{shop_items.count} shop items"

      {
        id: category.id,
        title: category.title,
        breadcrumb: build_breadcrumb(category),
        path: category.path,
        shop_items_count: category.shop_items.approved.count,
        shop_items: shop_items.map do |item|
          latest_update = item.shop_item_updates.order(created_at: :desc).first
          {
            id: item.id,
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
        end,
      }
    end
    #sort by shop item count desc
    formatted_categories.sort_by! { |cat| -cat[:shop_items_count] }
    #sort shopitems in catregories by lowest price
    formatted_categories.each do |cat|
      cat[:shop_items].sort_by! { |item| item[:latest_price] || Float::INFINITY }
    end
    render json: formatted_categories
  end

  private

  def build_breadcrumb(category)
    # Build breadcrumb manually if breadcrumbs method doesn't exist
    breadcrumb_parts = []
    current_category = category

    while current_category
      breadcrumb_parts.unshift(current_category.title)
      current_category = current_category.parent
    end
    #remove last part if it is "Products"
    breadcrumb_parts.pop
    breadcrumb_parts
  rescue => e
    Rails.logger.warn "Failed to build breadcrumb for category #{category.id}: #{e.message}"
    # Fallback to category title if breadcrumb building fails
    [category.title]
  end

  SIMILARITY_THRESHOLD = 0.2 # Adjust this value between 0.0 and 1.0

  def find_similar_categories(query)
    return [] unless ShopItemCategoryMatcher.send(:pg_trgm_available?)

    sanitized_query = ActiveRecord::Base.connection.quote(query.downcase)
    Rails.logger.debug "Searching categories with query: #{query}"

    # Look for categories.title and path
    sql = <<~SQL
      SELECT categories.*, 
             GREATEST(
               similarity(categories.title, #{sanitized_query}),
               similarity(categories.path, #{sanitized_query})
             ) as sim_score
      FROM categories
      WHERE category_type = #{Category.category_types[:product]}
        AND (
          similarity(categories.title, #{sanitized_query}) > #{SIMILARITY_THRESHOLD}
          OR similarity(categories.path, #{sanitized_query}) > #{SIMILARITY_THRESHOLD}
        )
      ORDER BY sim_score DESC
      LIMIT 3
    SQL

    results = ActiveRecord::Base.connection.exec_query(sql)

    # Load full Category objects with associations
    category_ids = results.map { |result| result["id"] }
    categories = Category.where(id: category_ids).includes(:shop_items, :parent)

    # Maintain the order from the SQL query and add sim_score
    results.map do |result|
      category = categories.find { |c| c.id == result["id"].to_i }
      if category
        category.define_singleton_method(:sim_score) { result["sim_score"].to_f }
        category
      end
    end.compact
  rescue => e
    Rails.logger.error "Error in category search: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    []
  end
end
