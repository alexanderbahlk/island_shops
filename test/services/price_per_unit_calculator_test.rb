require "test_helper"

class PricePerUnitCalculatorTest < ActiveSupport::TestCase
  # Tests for weight units - all normalized to 100g
  test "calculate returns correct values for grams (100g base)" do
    result = PricePerUnitCalculator.calculate(5.00, 200, "g")

    assert_not_nil result
    assert_equal 2.5, result[:display_value]
    assert_equal 2.5, result[:value]
    assert_equal 100, result[:base_quantity]
    assert_equal "100g", result[:normalized_unit]
  end

  test "calculate returns correct values for kilograms (normalized to 100g)" do
    result = PricePerUnitCalculator.calculate(10.00, 2, "kg")

    assert_not_nil result
    assert_equal 0.5, result[:display_value] # $10 / 2000g * 100g = $0.50 per 100g
    assert_equal 0.5, result[:value]
    assert_equal 100, result[:base_quantity]
    assert_equal "100g", result[:normalized_unit]
  end

  test "calculate returns correct values for pounds (normalized to 100g)" do
    result = PricePerUnitCalculator.calculate(4.54, 1, "lbs")

    assert_not_nil result
    assert_equal 1.0, result[:display_value] # $4.54 / 453.592g * 100g ≈ $1.00 per 100g
    assert_equal 1.0009, result[:value]
    assert_equal 100, result[:base_quantity]
    assert_equal "100g", result[:normalized_unit]
  end

  test "calculate returns correct values for ounces (normalized to 100g)" do
    result = PricePerUnitCalculator.calculate(2.83, 1, "oz")

    assert_not_nil result
    assert_equal 9.98, result[:display_value] # $2.83 / 28.3495g * 100g ≈ $10.00 per 100g
    assert_equal 9.9825, result[:value]
    assert_equal 100, result[:base_quantity]
    assert_equal "100g", result[:normalized_unit]
  end

  # Tests for volume units
  test "calculate returns correct values for milliliters (100ml base)" do
    result = PricePerUnitCalculator.calculate(3.00, 250, "ml")

    assert_not_nil result
    assert_equal 1.2, result[:display_value]
    assert_equal 1.2, result[:value]
    assert_equal 100, result[:base_quantity]
    assert_equal "100ml", result[:normalized_unit]
  end

  test "calculate returns correct values for liters (1l base)" do
    result = PricePerUnitCalculator.calculate(8.00, 2, "l")

    assert_not_nil result
    assert_equal 0.4, result[:display_value]
    assert_equal 0.4, result[:value]
    assert_equal 100, result[:base_quantity]
    assert_equal "100ml", result[:normalized_unit]
  end

  test "calculate returns correct values for fluid ounces (1fl base)" do
    result = PricePerUnitCalculator.calculate(4.50, 16, "fl")

    assert_not_nil result
    assert_equal 0.28, result[:display_value]
    assert_equal 0.2813, result[:value]
    assert_equal 1, result[:base_quantity]
    assert_equal "1fl", result[:normalized_unit]
  end

  test "calculate returns correct values for alu foil in feet" do
    result = PricePerUnitCalculator.calculate(25.95, 120, "ft")

    assert_not_nil result
    assert_equal 0.22, result[:display_value]
    assert_equal 0.2163, result[:value]
    assert_equal 1, result[:base_quantity]
    assert_equal "1ft", result[:normalized_unit]
  end

  # Tests for count/piece units
  test "calculate returns correct values for pieces (1pc base)" do
    result = PricePerUnitCalculator.calculate(12.00, 6, "pc")

    assert_not_nil result
    assert_equal 2.0, result[:display_value]
    assert_equal 2.0, result[:value]
    assert_equal 1, result[:base_quantity]
    assert_equal "1pc", result[:normalized_unit]
  end

  test "calculate returns correct values for count (1ct base)" do
    result = PricePerUnitCalculator.calculate(15.99, 16, "ct")

    assert_not_nil result
    assert_equal 1.0, result[:display_value]
    assert_equal 0.9994, result[:value]
    assert_equal 1, result[:base_quantity]
    assert_equal "1ct", result[:normalized_unit]
  end

  test "calculate returns correct values for each (1each base)" do
    result = PricePerUnitCalculator.calculate(2.50, 1, "each")

    assert_not_nil result
    assert_equal 2.5, result[:display_value]
    assert_equal 2.5, result[:value]
    assert_equal 1, result[:base_quantity]
    assert_equal "each", result[:normalized_unit]
  end

  test "calculate returns correct values for N/A unit" do
    result = PricePerUnitCalculator.calculate(5.00, 2, "N/A")

    assert_not_nil result
    assert_equal 2.5, result[:display_value]
    assert_equal 2.5, result[:value]
    assert_equal 1, result[:base_quantity]
    assert_equal "1unit", result[:normalized_unit]
  end

  # Precision and rounding tests
  test "calculate rounds display value to 2 decimal places" do
    result = PricePerUnitCalculator.calculate(1.00, 3, "each")

    assert_equal 0.33, result[:display_value]
    assert_equal 0.3333, result[:value]
  end

  test "calculate rounds value to 4 decimal places" do
    result = PricePerUnitCalculator.calculate(1.00, 7, "each")

    assert_equal 0.14, result[:display_value]
    assert_equal 0.1429, result[:value]
  end

  # Invalid input tests
  test "calculate returns nil for invalid unit" do
    result = PricePerUnitCalculator.calculate(5.00, 200, "invalid")

    assert_nil result
  end

  test "calculate returns nil for zero price" do
    result = PricePerUnitCalculator.calculate(0, 200, "g")

    assert_nil result
  end

  test "calculate returns nil for negative price" do
    result = PricePerUnitCalculator.calculate(-5.00, 200, "g")

    assert_nil result
  end

  test "calculate returns nil for zero size" do
    result = PricePerUnitCalculator.calculate(5.00, 0, "g")

    assert_nil result
  end

  test "calculate returns nil for negative size" do
    result = PricePerUnitCalculator.calculate(5.00, -200, "g")

    assert_nil result
  end

  test "calculate returns nil for nil price" do
    result = PricePerUnitCalculator.calculate(nil, 200, "g")

    assert_nil result
  end

  test "calculate returns nil for nil size" do
    result = PricePerUnitCalculator.calculate(5.00, nil, "g")

    assert_nil result
  end

  test "calculate returns nil for blank unit" do
    result = PricePerUnitCalculator.calculate(5.00, 200, "")

    assert_nil result
  end

  # Tests for calculate_value_only method (updated format)
  test "calculate_value_only returns hash with price_per_unit and normalized_unit when valid" do
    result = PricePerUnitCalculator.calculate_value_only(5.00, 200, "g")

    assert_not_nil result
    assert_equal 2.5, result[:price_per_unit]
    assert_equal "100g", result[:normalized_unit]
  end

  test "calculate_value_only returns hash for weight conversions" do
    result = PricePerUnitCalculator.calculate_value_only(10.00, 2, "kg")

    assert_not_nil result
    assert_equal 0.5, result[:price_per_unit]
    assert_equal "100g", result[:normalized_unit]
  end

  test "calculate_value_only returns nil when invalid" do
    result = PricePerUnitCalculator.calculate_value_only(0, 200, "g")

    assert_nil result
  end

  # Tests for should_calculate? method
  test "should_calculate? returns true for valid inputs" do
    result = PricePerUnitCalculator.should_calculate?(5.00, 200, "g")

    assert result
  end

  test "should_calculate? returns false for N/A unit" do
    result = PricePerUnitCalculator.should_calculate?(5.00, 200, "N/A")

    refute result
  end

  test "should_calculate? returns false for invalid unit" do
    result = PricePerUnitCalculator.should_calculate?(5.00, 200, "invalid")

    refute result
  end

  test "should_calculate? returns false for zero price" do
    result = PricePerUnitCalculator.should_calculate?(0, 200, "g")

    refute result
  end

  test "should_calculate? returns false for zero size" do
    result = PricePerUnitCalculator.should_calculate?(5.00, 0, "g")

    refute result
  end

  test "should_calculate? returns false for nil values" do
    refute PricePerUnitCalculator.should_calculate?(nil, 200, "g")
    refute PricePerUnitCalculator.should_calculate?(5.00, nil, "g")
    refute PricePerUnitCalculator.should_calculate?(5.00, 200, nil)
  end

  # Weight conversion accuracy tests
  test "weight conversion accuracy for kilograms" do
    # 1kg = 1000g, so $10/1kg should be $1 per 100g
    result = PricePerUnitCalculator.calculate(10.00, 1, "kg")
    assert_equal 1.0, result[:display_value]
  end

  test "weight conversion accuracy for pounds" do
    # 1lb = 453.592g, so $4.54/1lb should be ~$1 per 100g
    result = PricePerUnitCalculator.calculate(4.54, 1, "lbs")
    assert_in_delta 1.0, result[:display_value], 0.01
  end

  test "weight conversion accuracy for ounces" do
    # 1oz = 28.3495g, so $2.83/1oz should be ~$10 per 100g
    result = PricePerUnitCalculator.calculate(2.83, 1, "oz")
    assert_in_delta 10.0, result[:display_value], 0.1
  end

  # Edge case tests
  test "handles decimal values correctly" do
    result = PricePerUnitCalculator.calculate(4.99, 0.5, "kg")
    # 0.5kg = 500g, so $4.99/500g * 100g = $0.998 per 100g
    assert_equal 1.0, result[:display_value]
    assert_equal "100g", result[:normalized_unit]
  end

  test "handles very small quantities" do
    result = PricePerUnitCalculator.calculate(0.50, 25, "ml")
    # $0.50/25ml * 100ml = $2.00 per 100ml
    assert_equal 2.0, result[:display_value]
    assert_equal "100ml", result[:normalized_unit]
  end

  test "handles large quantities" do
    result = PricePerUnitCalculator.calculate(50.00, 5000, "g")
    # $50/5000g * 100g = $1.00 per 100g
    assert_equal 1.0, result[:display_value]
    assert_equal "100g", result[:normalized_unit]
  end

  # Integration tests with real-world scenarios
  test "integration with actual price scenarios" do
    # 500g item at $5.00 → $1.00 per 100g
    result = PricePerUnitCalculator.calculate(5.00, 500, "g")
    assert_equal 1.0, result[:display_value]
    assert_equal "100g", result[:normalized_unit]

    # 2kg item at $10.00 → $0.50 per 100g (not $5.00 per kg anymore)
    result = PricePerUnitCalculator.calculate(10.00, 2, "kg")
    assert_equal 0.5, result[:display_value]
    assert_equal "100g", result[:normalized_unit]

    # 250ml item at $3.00 → $1.20 per 100ml
    result = PricePerUnitCalculator.calculate(3.00, 250, "ml")
    assert_equal 1.2, result[:display_value]
    assert_equal "100ml", result[:normalized_unit]

    # 1 piece at $2.50 → $2.50 per piece
    result = PricePerUnitCalculator.calculate(2.50, 1, "each")
    assert_equal 2.5, result[:display_value]
    assert_equal "each", result[:normalized_unit]

    # 12 pieces at $12.00 → $1.00 per piece
    result = PricePerUnitCalculator.calculate(12.00, 12, "pc")
    assert_equal 1.0, result[:display_value]
    assert_equal "1pc", result[:normalized_unit]

    # 16 count at $15.99 → $1.00 per count
    result = PricePerUnitCalculator.calculate(15.99, 16, "ct")
    assert_equal 1.0, result[:display_value]
    assert_equal "1ct", result[:normalized_unit]

    # 1 gallon at $3.79 → ~$0.10 per 100ml
    result = PricePerUnitCalculator.calculate(3.79, 1, "gal")
    assert_in_delta 0.1, result[:display_value], 0.01
    assert_equal "100ml", result[:normalized_unit]

    # 1 pint at $1.89 → ~$0.40 per 100ml
    result = PricePerUnitCalculator.calculate(1.89, 1, "pt")
    assert_in_delta 0.4, result[:display_value], 0.01
    assert_equal "100ml", result[:normalized_unit]

    # 1 quart at $1.49 → ~$0.16 per 100ml
    result = PricePerUnitCalculator.calculate(1.49, 1, "qt")
    assert_in_delta 0.16, result[:display_value], 0.01
    assert_equal "100ml", result[:normalized_unit]

    # 16 fluid ounces at $4.50 → ~$0.28 per fl oz
    result = PricePerUnitCalculator.calculate(4.50, 16, "fl")
    assert_equal 0.28, result[:display_value]
    assert_equal "1fl", result[:normalized_unit]

    # 120 feet at $25.95 → ~$0.22 per foot
    result = PricePerUnitCalculator.calculate(25.95, 120, "ft")
    assert_equal 0.22, result[:display_value]
    assert_equal "1ft", result[:normalized_unit]

    # 1 pack at $3.99 → $3.99 per pack
    result = PricePerUnitCalculator.calculate(3.99, 1, "pk")
    assert_equal 3.99, result[:display_value]
    assert_equal "1pc", result[:normalized_unit]

    # 1 whole item at $29.99 → $29.99 per each
    result = PricePerUnitCalculator.calculate(29.99, 1, "whole")
    assert_equal 29.99, result[:display_value]
    assert_equal "each", result[:normalized_unit]
  end

  test "weight units all normalize to 100g base for comparison" do
    # Different weight units should all be comparable on 100g basis
    gram_result = PricePerUnitCalculator.calculate(1.00, 100, "g")
    kg_result = PricePerUnitCalculator.calculate(10.00, 1, "kg")

    # Both should give same price per 100g
    assert_equal 1.0, gram_result[:display_value]
    assert_equal 1.0, kg_result[:display_value]
    assert_equal "100g", gram_result[:normalized_unit]
    assert_equal "100g", kg_result[:normalized_unit]
  end
end
