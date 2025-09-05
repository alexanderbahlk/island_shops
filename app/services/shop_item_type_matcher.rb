class ShopItemTypeMatcher
  SIMILARITY_THRESHOLD = 0.3 # Adjust this value between 0.0 and 1.0
  MAX_SUGGESTIONS = 5

  def self.find_best_match(title)
    return nil if title.blank?

    # Clean and normalize the title
    normalized_title = normalize_title(title)

    # Try exact match first
    exact_match = ShopItemType.find_by("LOWER(title) = ?", normalized_title.downcase)
    return exact_match if exact_match

    if !pg_trgm_available?
      Rails.logger.warn "pg_trgm extension is not available in the database. Cannot perform fuzzy matching."
      return nil
    end

    # Use raw SQL to avoid parameter binding issues
    begin
      sanitized_title = ActiveRecord::Base.connection.quote(normalized_title)

      sql = <<~SQL
        SELECT shop_item_types.*, similarity(shop_item_types.title, #{sanitized_title}) as sim_score
        FROM shop_item_types
        WHERE similarity(shop_item_types.title, #{sanitized_title}) > #{SIMILARITY_THRESHOLD}
        ORDER BY similarity(shop_item_types.title, #{sanitized_title}) DESC
        LIMIT #{MAX_SUGGESTIONS}
      SQL

      results = ActiveRecord::Base.connection.exec_query(sql)

      return nil if results.empty?

      # Convert the first result back to a ShopItemType object
      first_result = results.first
      type = ShopItemType.find(first_result["id"])
      type.define_singleton_method(:sim_score) { first_result["sim_score"].to_f }
      type
    rescue => e
      Rails.logger.error "Error in find_best_match: #{e.message}"
      nil
    end
  end

  def self.find_similar_types(title, limit: MAX_SUGGESTIONS)
    return [] if title.blank?

    normalized_title = normalize_title(title)

    if !pg_trgm_available?
      Rails.logger.warn "pg_trgm extension is not available in the database. Cannot perform fuzzy matching."
      return []
    end

    begin
      sanitized_title = ActiveRecord::Base.connection.quote(normalized_title)

      sql = <<~SQL
        SELECT shop_item_types.*, similarity(shop_item_types.title, #{sanitized_title}) as sim_score
        FROM shop_item_types
        WHERE similarity(shop_item_types.title, #{sanitized_title}) > #{SIMILARITY_THRESHOLD}
        ORDER BY similarity(shop_item_types.title, #{sanitized_title}) DESC
        LIMIT #{limit}
      SQL

      results = ActiveRecord::Base.connection.exec_query(sql)

      results.map do |row|
        type = ShopItemType.find(row["id"])
        { type: type, similarity: row["sim_score"].to_f }
      end
    rescue => e
      Rails.logger.error "Error in find_similar_types: #{e.message}"
      []
    end
  end

  def self.extract_type_keywords(title)
    return [] if title.blank?

    # Load type_keywords from ShopItemType.all
    begin
      type_keywords = ShopItemType.pluck(:title).map(&:downcase)
    rescue => e
      Rails.logger.error "Error loading type keywords: #{e.message}"
      return []
    end

    normalized_title = normalize_title(title).downcase
    found_keywords = type_keywords.select { |keyword| normalized_title.include?(keyword) }

    # Also extract potential brand names (words in title that might be types)
    words = normalized_title.split(/\s+/).reject { |word| word.length < 3 }

    (found_keywords + words).uniq
  end

  private

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

    # Remove size/unit information and common noise words
    normalized = title.dup

    # Remove size patterns (e.g., "500ml", "2kg", "12 pack")
    normalized.gsub!(/\b\d+\s*(ml|l|g|kg|oz|lb|pack|count|ct|pieces?)\b/i, "")

    # Remove brand indicators
    normalized.gsub!(/\b(organic|fresh|premium|select|choice|grade a)\b/i, "")

    # Remove extra whitespace
    normalized.gsub!(/\s+/, " ")
    normalized.strip
  end
end
