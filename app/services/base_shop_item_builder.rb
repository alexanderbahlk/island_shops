class BaseShopItemBuilder
  attr_reader :shop_item, :shop_item_update, :errors

  def initialize; end

  protected

  def build_shop_item_update
    @shop_item_update = @shop_item.shop_item_updates.build(@shop_item_update_params)

    # Calculate price_per_unit using the smart calculator
    return unless PricePerUnitCalculator.should_calculate?(@shop_item_update.price, @shop_item.size, @shop_item.unit)

    calculation_result = PricePerUnitCalculator.calculate_value_only(
      @shop_item_update.price,
      @shop_item.size,
      @shop_item.unit
    )

    return unless calculation_result

    @shop_item_update.price_per_unit = calculation_result[:price_per_unit]
    # Also store the normalized_unit if you have a field for it
    @shop_item_update.normalized_unit = calculation_result[:normalized_unit]
  end

  def auto_assign_shop_item_category
    return if @shop_item.title.blank?

    best_match = FindCategoryForShopItemService.new(shop_item: @shop_item).find

    return unless best_match

    @shop_item.category = best_match
    @category_match_info = {
      matched: true,
      category: best_match.title,
      similarity: best_match.respond_to?(:sim_score) ? best_match.sim_score : nil,
      method: 'fuzzy_match'
    }

    Rails.logger.info "Auto-assigned ShopItemType '#{best_match.title}' to '#{@shop_item.title}'"
  end

  def set_shop_item_size_and_unit_from_title
    return if @shop_item.title.blank?

    parsed_data = UnitParser.parse_from_title(@shop_item.title)

    @shop_item.size = parsed_data[:size] if @shop_item.size.blank? && parsed_data[:size].present?
    @shop_item.unit = parsed_data[:unit] if @shop_item.unit.blank? && parsed_data[:unit].present?
  end
end
