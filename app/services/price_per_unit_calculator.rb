class PricePerUnitCalculator
  # Base quantities for normalized price comparison
  BASE_QUANTITIES = {
    "g" => 100,      # Price per 100g
    "kg" => 100,     # Price per 100g (converted from kg)
    "lbs" => 100,    # Price per 100g (converted from lbs)
    "ml" => 100,     # Price per 100ml
    "l" => 100,      # Price per 100ml (converted from l)
    "gal" => 100,    # Price per 100ml (converted from gal)
    "qt" => 100,    # Price per 100ml (converted from gal)
    "oz" => 100,     # Price per 100g (converted from oz)
    "ft" => 1,       # Price per 1 ft
    "fl" => 1,       # Price per 1 fl
    "pc" => 1,       # Price per 1 piece
    "pk" => 1,       # Price per 1 pack
    "ct" => 1,       # Price per 1 count
    "whole" => 1,     # Price per 1 whole
    "each" => 1,     # Price per 1 each
    "N/A" => 1,      # Price per 1 unit (when unit is unknown)
  }.freeze

  # Conversion factors to grams
  WEIGHT_TO_GRAMS = {
    "g" => 1,
    "kg" => 1000,
    "lbs" => 453.592,  # 1 pound = 453.592 grams
    "oz" => 28.3495,    # 1 ounce = 28.3495 grams
  }.freeze

  # Conversion factors to milliliters
  VOLUME_TO_ML = {
    "ml" => 1,
    "l" => 1000,        # 1 liter = 1000 milliliters
    "gal" => 3785.41,   # 1 US gallon = 3785.41 milliliters
    "qt" => 946.353,    # 1 US quart = 946.353 milliliters
  }.freeze

  # Normalized unit labels
  NORMALIZED_UNITS = {
    "ft" => "1ft",
    "g" => "100g",
    "kg" => "100g",
    "lbs" => "100g",
    "oz" => "100g",
    "ml" => "100ml",
    "gal" => "100ml",
    "qt" => "100ml",
    "l" => "100ml",
    "fl" => "1fl",
    "pc" => "1pc",
    "whole" => "each",
    "pk" => "1pc",
    "ct" => "1ct",
    "each" => "each",
    "N/A" => "1unit",
  }.freeze

  def self.calculate(price, size, unit)
    Rails.logger.info "Calculating price per unit for price: #{price}, size: #{size}, unit: #{unit}"
    return nil unless valid_inputs?(price, size, unit)

    base_quantity = BASE_QUANTITIES[unit]
    return nil unless base_quantity

    # Convert weight units to grams first
    if WEIGHT_TO_GRAMS.key?(unit)
      size_in_grams = size * WEIGHT_TO_GRAMS[unit]
      price_per_unit = (price * base_quantity) / size_in_grams
      # Convert volume units to milliliters
    elsif VOLUME_TO_ML.key?(unit)
      size_in_ml = size * VOLUME_TO_ML[unit]
      price_per_unit = (price * base_quantity) / size_in_ml
    else
      price_per_unit = (price * base_quantity) / size
    end

    {
      value: price_per_unit.round(4),
      display_value: price_per_unit.round(2),
      base_quantity: base_quantity,
      normalized_unit: NORMALIZED_UNITS[unit],
    }
  end

  def self.calculate_value_only(price, size, unit)
    result = calculate(price, size, unit)
    return nil unless result

    {
      price_per_unit: result[:display_value],
      normalized_unit: result[:normalized_unit],
    }
  end

  def self.should_calculate?(price, size, unit)
    valid_inputs?(price, size, unit) &&
    UnitParser.valid_unit?(unit) &&
    unit != "N/A"  # Optional: skip calculation for unknown units
  end

  private

  def self.valid_inputs?(price, size, unit)
    price.present? &&
    price.is_a?(Numeric) &&
    price > 0 &&
    size.present? &&
    size.is_a?(Numeric) &&
    size > 0 &&
    unit.present? &&
    UnitParser.valid_unit?(unit)
  end
end
