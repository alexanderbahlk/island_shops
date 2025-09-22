class ShopItemCategoryMatcher
  include PgSearchChecker
  include TitleNormalizer

  SIMILARITY_THRESHOLD = 0.22 # Adjust this value between 0.0 and 1.0

  attr_reader :shop_item

  def initialize(shop_item:)
    @shop_item = shop_item
  end

  def find_best_match()
    if shop_item.blank?
      Rails.logger.warn "No shop item provided for category matching."
      return nil
    end

    return nil unless pg_trgm_available?

    category = find_category_by_breadcrumb(shop_item.breadcrumb)

    if category.nil?
      category = find_category_by_title(shop_item.title)
    end

    return category
  end

  private

  def find_category_by_breadcrumb(breadcrumb)
    # Clean and normalize the breadcrumb
    normalized_breadcrumb = normalize_title(breadcrumb)
    find_fuzzy_match(normalized_breadcrumb)
  end

  def find_category_by_title(title)
    # Clean and normalize the title
    normalized_title = normalize_title(title)
    find_fuzzy_match(normalized_title)
  end

  def find_fuzzy_match(shop_item_text)
    begin
      # Extract the last part of the path (product name) and also try full path matching
      # e.g.: "groceries coffee & tea freeze dried instant coffee"
      sanitized_shop_item_text = ActiveRecord::Base.connection.quote(shop_item_text)

      #look for categories.path
      #e.g.: food/beverages/hot-beverages/coffee
      sql = <<~SQL
        SELECT categories.*,
               GREATEST(
                 similarity(categories.path, #{sanitized_shop_item_text}),
                 similarity(split_part(categories.path, '/', array_length(string_to_array(categories.path, '/'), 1)), #{sanitized_shop_item_text}),
                 similarity(categories.title, #{sanitized_shop_item_text}),
                 COALESCE((
                   SELECT MAX(similarity(syn, #{sanitized_shop_item_text}))
                   FROM unnest(categories.synonyms) AS syn
                 ), 0)
               ) as sim_score
        FROM categories
        WHERE category_type = #{Category.category_types[:product]}
          AND (
            similarity(categories.path, #{sanitized_shop_item_text}) > #{SIMILARITY_THRESHOLD}
            OR similarity(split_part(categories.path, '/', array_length(string_to_array(categories.path, '/'), 1)), #{sanitized_shop_item_text}) > #{SIMILARITY_THRESHOLD}
            OR similarity(categories.title, #{sanitized_shop_item_text}) > #{SIMILARITY_THRESHOLD}
            OR EXISTS (
              SELECT 1 FROM unnest(categories.synonyms) AS syn
              WHERE similarity(syn, #{sanitized_shop_item_text}) > #{SIMILARITY_THRESHOLD}
            )
          )
        ORDER BY sim_score DESC
        LIMIT 1
      SQL

      results = ActiveRecord::Base.connection.exec_query(sql)

      return nil if results.empty?

      # Convert the first result back to a Category object
      first_result = results.first
      category = Category.find(first_result["id"])
      category.define_singleton_method(:sim_score) { first_result["sim_score"].to_f }
      category
    rescue => e
      Rails.logger.error "Error in find_fuzzy_match: #{e.message}"
      nil
    end
  end
end
