module UnitParser
  VALID_UNITS = %w[
    ft
    whole
    ct
    pc
    pk
    each
    g
    kg
    lbs
    l
    ml
    oz
    fz
    gal
    qt
    fl
    unit
    N/A
  ].freeze

  UNIT_PATTERNS = {
    "ft" => /(\d+(?:\.\d+)?)\s*ft\s*$/i,
    "ct" => /(?:(\d+(?:\.\d+)?)\s*)?ct\s*$/i,
    "lbs" => /(\d+(?:\.\d+)?)\s*lbs\s*$/i,
    "lb" => /(\d+(?:\.\d+)?)\s*lb\s*$/i,
    "packs" => /(?:(\d+(?:\.\d+)?)\s*)?packs\s*$/i,
    "pack" => /(?:(\d+(?:\.\d+)?)\s*)?pack\s*/i,
    "pcs" => /(?:(\d+(?:\.\d+)?)\s*)?pcs\s*$/i,
    "pc" => /(?:(\d+(?:\.\d+)?)\s*)?pc\s*$/i,
    "each" => /(?:(\d+(?:\.\d+)?)\s*)?(each|\[each\])\s*$/i,
    "g" => /(\d+(?:\.\d+)?)\s*(g|gr)\s*$/i,
    "kg" => /(\d+(?:\.\d+)?)\s*kg\s*$/i,
    "lt" => /(\d+(?:\.\d+)?)\s*lt\s*$/i,
    "l" => /(\d+(?:\.\d+)?)\s*l\s*$/i,
    "ml" => /(\d+(?:\.\d+)?)\s*ml\s*$/i,
    "oz" => /(\d+(?:\.\d+)?)\s*oz\s*$/i,
    "fz" => /(\d+(?:\.\d+)?)\s*fz\s*$/i,
    "fl" => /(\d+(?:\.\d+)?)\s*fl\s*$/i,
    "gal" => /(\d+(?:\.\d+)?)\s*gal\s*$/i,
    "qt" => /(\d+(?:\.\d+)?)\s*qt\s*$/i,
    "whole" => /(?:(\d+(?:\.\d+)?)\s*)?whole\s*/i,
    "kg_per" => /(?:(\d+(?:\.\d+)?)\s*)?\[per\s*kg\]/i,
    "unit" => /(?:(\d+(?:\.\d+)?)\s*)?unit\s*$/i,
  }.freeze

  # Extended aliases for fuzzy matching
  UNIT_ALIASES = {
    "feet" => "ft",
    "pounds" => "lbs",
    "lb" => "lbs",
    "gr" => "g",
    "gram" => "g",
    "grams" => "g",
    "pack" => "pk",
    "packs" => "pk",
    "pcs" => "pk",
    "piece" => "pc",
    "pieces" => "pc",
    "piece(s)" => "pc",
    "whole" => "pc",
    "count" => "ct",
    "quart" => "qt",
    "gallon" => "gal",
    "gallons" => "gal",
    "lt" => "l",
    "liter" => "l",
    "liters" => "l",
    "litre" => "l",
    "litres" => "l",
    "milliliter" => "ml",
    "milliliters" => "ml",
    "millilitre" => "ml",
    "millilitres" => "ml",
    "mL" => "ml",
    "[per kg]" => "kg",
    "kilogram" => "kg",
    "kilograms" => "kg",
    "kg_per" => "kg",
    "ounce" => "oz",
    "ounces" => "oz",
    "fluid" => "fl",
    "each" => "each",
    "[each]" => "each",
    "ea" => "each",
    "n/a" => "N/A",
    "na" => "N/A",
  }.freeze

  ONE_SIZE_FROM_UNITS = %w[pk whole].freeze

  def self.parse_from_title(title)
    return { size: nil, unit: nil } if title.blank?

    # Check for specific unit patterns first
    UNIT_PATTERNS.each do |unit, pattern|
      match = title.match(pattern)
      if match
        normalized_unit = normalize_unit(unit)
        #if normalized_unit is in ONE_SIZE_FROM_UNITS and size is nil, set size to 1
        if ONE_SIZE_FROM_UNITS.include?(normalized_unit) && match[1].nil?
          return {
                   size: 1.0,
                   unit: normalized_unit,
                 }
        end

        return {
                 size: match[1].to_f,
                 unit: normalized_unit,
               }
      end
    end

    # Check for standalone number at the end (default to N/A unit)
    size_match = title.match(/(\d+(?:\.\d+)?)\s*$/)
    if size_match
      return {
               size: size_match[1].to_f,
               unit: "N/A",
             }
    end

    { size: nil, unit: nil }
  end

  def self.normalize_unit(unit)
    return nil if unit.blank?

    normalized = unit.downcase.strip

    # First check exact match with valid units
    return normalized if VALID_UNITS.include?(normalized)

    # Then check aliases
    return UNIT_ALIASES[normalized] if UNIT_ALIASES.key?(normalized)

    # Fuzzy search using Levenshtein distance
    best_match = fuzzy_match(normalized)
    return best_match if best_match

    nil
  end

  def self.valid_unit?(unit)
    VALID_UNITS.include?(unit)
  end

  private

  def self.fuzzy_match(input, threshold: 2)
    return nil if input.length < 2 # Too short for meaningful fuzzy matching

    best_match = nil
    best_distance = Float::INFINITY

    # Check against valid units
    VALID_UNITS.each do |valid_unit|
      distance = levenshtein_distance(input, valid_unit)
      if distance < best_distance && distance <= threshold
        best_distance = distance
        best_match = valid_unit
      end
    end

    # Also check against alias keys for better matching
    UNIT_ALIASES.keys.each do |alias_key|
      distance = levenshtein_distance(input, alias_key)
      if distance < best_distance && distance <= threshold
        best_distance = distance
        best_match = UNIT_ALIASES[alias_key]
      end
    end

    best_match
  end

  def self.levenshtein_distance(str1, str2)
    matrix = Array.new(str1.length + 1) { Array.new(str2.length + 1) }

    (0..str1.length).each { |i| matrix[i][0] = i }
    (0..str2.length).each { |j| matrix[0][j] = j }

    (1..str1.length).each do |i|
      (1..str2.length).each do |j|
        cost = str1[i - 1] == str2[j - 1] ? 0 : 1
        matrix[i][j] = [
          matrix[i - 1][j] + 1,     # deletion
          matrix[i][j - 1] + 1,     # insertion
          matrix[i - 1][j - 1] + cost, # substitution
        ].min
      end
    end

    matrix[str1.length][str2.length]
  end
end
