class ShopItemCategoryMatcher
  SIMILARITY_THRESHOLD = 0.22 # Adjust this value between 0.0 and 1.0

  def self.find_best_match(shop_item)
    if shop_item.blank?
      Rails.logger.warn "No shop item provided for category matching."
      return nil
    end

    if !pg_trgm_available?
      Rails.logger.warn "pg_trgm extension is not available in the database. Cannot perform fuzzy matching."
      return nil
    end

    category = find_category_by_breadcrumb(shop_item.breadcrumb)

    if category.nil?
      category = find_category_by_title(shop_item.title)
    end

    return category
  end

  private

  def self.find_category_by_breadcrumb(breadcrumb)
    # Clean and normalize the breadcrumb
    normalized_breadcrumb = normalize_title(breadcrumb)
    find_fuzzy_match(normalized_breadcrumb)
  end

  def self.find_category_by_title(title)
    # Clean and normalize the title
    normalized_title = normalize_title(title)
    find_fuzzy_match(normalized_title)
  end

  def self.find_fuzzy_match(shop_item_text)
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

  def self.pg_trgm_available?
    @pg_trgm_available ||= begin
        result = ActiveRecord::Base.connection.execute("SELECT 1 FROM pg_extension WHERE extname = 'pg_trgm'")
        result.any?
      rescue => e
        Rails.logger.warn "pg_trgm extension check failed: #{e.message}"
        false
      end
  end

  def self.normalize_title(title)
    return "" if title.blank?

    # Handle the specific format: "Shop / Grocery / Canned Goods, Soups, & Broths / Canned Vegetables / Hunts Tomatoes Diced 8 14.5"
    normalized = title.dup

    if normalized.count(">") > 1
      parts = normalized.split(/\s*\>\s+/)
    elsif normalized.count("/") > 1
      parts = normalized.split(/\s*\/\s+/)
    else
      parts = nil
    end

    if parts && parts.length > 1
      # Skip "Shop" and "Grocery" if they exist at the beginning
      # Skip Brand names like "Member's Selection"
      relevant_parts = parts.drop_while { |part| part.downcase.match?(/^(pricesmart|home|shop|grocery)$/) }

      # Take the last 2-3 parts which are most likely to contain category and product info
      if relevant_parts.length > 2
        relevant_parts = relevant_parts.last(3)
      end

      # Join back with "/" to match the path format
      normalized = relevant_parts.join(">")
    end

    # Remove brand names and size information from the last part (product name)
    if normalized.include?(">")
      path_parts = normalized.split(">")
      product_part = path_parts.last

      # Clean the product part
      product_part = clean_product_name(product_part)

      # Reconstruct
      path_parts[-1] = product_part
      normalized = path_parts.join(" ")
    else
      # If no path structure, just clean the whole string
      normalized = clean_product_name(normalized)
    end

    # Convert to lowercase to match path format
    normalized.downcase.strip
  end

  def self.clean_product_name(product_name)
    cleaned = product_name.dup

    # Remove size patterns (e.g., "500ml", "2kg", "12 pack", "8 14.5")
    cleaned.gsub!(/\b\d+\.?\d*\s*(ml|l|g|kg|oz|lb|pack|count|ct|pieces?)\b/i, "")
    cleaned.gsub!(/\b(member's\s+selection|great\s+value|kirkland|store\s+brand?)\b/i, "")
    cleaned.gsub!(/\b(luxury|premium?)\b/i, "")
    cleaned.gsub!(/\b\d+\s+\d+\.?\d*\b/, "") # Remove patterns like "8 14.5"
    #remove / and - which are common in titles
    cleaned.gsub!(/[\/\-]/, " ")

    # Remove extra whitespace and punctuation
    cleaned.gsub!(/[,&]/, " ")
    cleaned.gsub!(/\s+/, " ")
    cleaned.strip
  end
end
