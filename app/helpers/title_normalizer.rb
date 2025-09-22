module TitleNormalizer
  def normalize_title(title)
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

  def clean_product_name(product_name)
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
