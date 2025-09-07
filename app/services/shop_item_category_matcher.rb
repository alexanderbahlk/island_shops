class ShopItemCategoryMatcher
  SIMILARITY_THRESHOLD = 0.1 # Adjust this value between 0.0 and 1.0
  MAX_SUGGESTIONS = 5

  def self.find_best_match(title)
    return nil if title.blank?

    # Clean and normalize the title
    normalized_title = normalize_title(title)

    # Use fuzzy matching if available
    if pg_trgm_available?
      return find_fuzzy_match(normalized_title)
    else
      Rails.logger.warn "pg_trgm extension is not available in the database. Cannot perform fuzzy matching."
      return nil
    end
  end

  def self.auto_assign_categories(shop_items = nil)
    # If no specific items provided, work with all items missing categories
    items_to_process = shop_items || ShopItem.missing_category

    results = {
      total_processed: 0,
      assigned: 0,
      skipped: 0,
      errors: [],
    }

    # Handle both arrays and ActiveRecord relations
    if items_to_process.is_a?(Array)
      items_to_process.each do |item|
        process_single_item(item, results)
      end
    else
      items_to_process.find_each do |item|
        process_single_item(item, results)
      end
    end

    results
  end

  def self.suggest_categories_for_item(shop_item)
    return [] if shop_item.title.blank?

    suggestions = find_similar_categories(shop_item.title)

    # Add context about why each category was suggested
    suggestions.map do |result|
      category = result[:category]
      {
        category: category,
        similarity: result[:similarity],
        breadcrumb: category.breadcrumbs.map(&:title).join(" > "),
        reason: determine_match_reason(shop_item.title, category.title, result[:similarity]),
      }
    end
  end

  private

  def self.process_single_item(item, results)
    results[:total_processed] += 1

    begin
      # Skip if item already has a category
      if item.category.present?
        results[:skipped] += 1
        return
      end

      # Try to find the best matching category
      best_match = find_best_match(item.title)

      if best_match
        item.update!(category: best_match)
        results[:assigned] += 1
        Rails.logger.info "Assigned '#{item.title}' to category '#{best_match.breadcrumbs.map(&:title).join(" > ")}'"
      else
        results[:skipped] += 1
        Rails.logger.info "No suitable category found for '#{item.title}'"
      end
    rescue => e
      results[:errors] << "Error processing '#{item.title}': #{e.message}"
      Rails.logger.error "Error auto-assigning category for item #{item.id}: #{e.message}"
    end
  end

  def self.find_fuzzy_match(normalized_title)
    begin
      # Extract the last part of the path (product name) and also try full path matching
      sanitized_title = ActiveRecord::Base.connection.quote(normalized_title)

      sql = <<~SQL
        SELECT categories.*, 
               GREATEST(
                 similarity(categories.path, #{sanitized_title}),
                 similarity(split_part(categories.path, '/', array_length(string_to_array(categories.path, '/'), 1)), #{sanitized_title}),
                 similarity(categories.title, #{sanitized_title})
               ) as sim_score
        FROM categories
        WHERE category_type = #{Category.category_types[:product]}
          AND (
            similarity(categories.path, #{sanitized_title}) > #{SIMILARITY_THRESHOLD}
            OR similarity(split_part(categories.path, '/', array_length(string_to_array(categories.path, '/'), 1)), #{sanitized_title}) > #{SIMILARITY_THRESHOLD}
            OR similarity(categories.title, #{sanitized_title}) > #{SIMILARITY_THRESHOLD}
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

  def self.find_similar_categories(title, limit: MAX_SUGGESTIONS)
    return [] if title.blank?

    normalized_title = normalize_title(title)

    if !pg_trgm_available?
      Rails.logger.warn "pg_trgm extension is not available in the database. Cannot perform fuzzy matching."
      return []
    end

    begin
      sanitized_title = ActiveRecord::Base.connection.quote(normalized_title)

      sql = <<~SQL
        SELECT categories.*, 
               GREATEST(
                 similarity(categories.path, #{sanitized_title}),
                 similarity(split_part(categories.path, '/', array_length(string_to_array(categories.path, '/'), 1)), #{sanitized_title}),
                 similarity(categories.title, #{sanitized_title})
               ) as sim_score
        FROM categories
        WHERE category_type = #{Category.category_types[:product]}
          AND (
            similarity(categories.path, #{sanitized_title}) > #{SIMILARITY_THRESHOLD}
            OR similarity(split_part(categories.path, '/', array_length(string_to_array(categories.path, '/'), 1)), #{sanitized_title}) > #{SIMILARITY_THRESHOLD}
            OR similarity(categories.title, #{sanitized_title}) > #{SIMILARITY_THRESHOLD}
          )
        ORDER BY sim_score DESC
        LIMIT #{limit}
      SQL

      results = ActiveRecord::Base.connection.exec_query(sql)

      results.map do |row|
        category = Category.find(row["id"])
        { category: category, similarity: row["sim_score"].to_f }
      end
    rescue => e
      Rails.logger.error "Error in find_similar_categories: #{e.message}"
      []
    end
  end

  def self.determine_match_reason(original_title, category_title, similarity)
    if similarity > 0.8
      "Very high similarity (#{(similarity * 100).round(1)}%)"
    elsif similarity > 0.6
      "High similarity (#{(similarity * 100).round(1)}%)"
    elsif original_title.downcase.include?(category_title.downcase)
      "Category name found in item title"
    elsif category_title.downcase.include?(original_title.downcase)
      "Item title found in category name"
    else
      "Moderate similarity (#{(similarity * 100).round(1)}%)"
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

    # Split by "/" and take relevant parts
    parts = normalized.split(/\s*\>\s+/)

    if parts.length > 1
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

  # New method to get category statistics
  def self.category_assignment_stats
    total_items = ShopItem.count
    assigned_items = ShopItem.joins(:category).count
    missing_items = ShopItem.missing_category.count

    {
      total_items: total_items,
      assigned_items: assigned_items,
      missing_items: missing_items,
      assignment_percentage: total_items > 0 ? (assigned_items.to_f / total_items * 100).round(2) : 0,
      total_product_categories: Category.products.count,
    }
  end
end
