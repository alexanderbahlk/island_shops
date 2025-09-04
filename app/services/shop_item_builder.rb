class ShopItemBuilder
  attr_reader :shop_item, :shop_item_update, :errors

  def initialize(shop_item_params, shop_item_update_params)
    @shop_item_params = shop_item_params
    @shop_item_update_params = shop_item_update_params
    @errors = []
  end

  def build
    existing_shop_item = ShopItem.find_by(url: @shop_item_params[:url])

    if existing_shop_item
      create_update_for_existing_item(existing_shop_item)
    else
      create_new_item_with_update
    end

    success?
  end

  def success?
    @errors.empty?
  end

  private

  def create_update_for_existing_item(existing_item)
    @shop_item = existing_item

    # Check if we need to create an update based on changes
    last_update = @shop_item.shop_item_updates.order(:created_at).last

    Rails.logger.debug "Last update: #{last_update.inspect}"

    should_create_update = last_update.nil? ||
                           last_update.price != @shop_item_update_params[:price] ||
                           last_update.stock_status != @shop_item_update_params[:stock_status]

    Rails.logger.debug "Should create update: #{should_create_update}"

    if should_create_update
      build_shop_item_update()

      unless @shop_item_update.save
        @errors.concat(@shop_item_update.errors.full_messages)
      end
    else
      @shop_item_update = last_update
    end
  end

  def create_new_item_with_update
    @shop_item = ShopItem.new(@shop_item_params)

    # set size and/or unit from title
    set_shop_item_size_and_unit_from_title()

    if @shop_item.save
      build_shop_item_update()

      unless @shop_item_update.save
        @errors.concat(@shop_item_update.errors.full_messages)
      end
    else
      @errors.concat(@shop_item.errors.full_messages)
    end
  end

  def set_shop_item_size_and_unit_from_title
    return if @shop_item.title.blank?

    parsed_data = UnitParser.parse_from_title(@shop_item.title)

    @shop_item.size = parsed_data[:size] if @shop_item.size.blank? && parsed_data[:size].present?
    @shop_item.unit = parsed_data[:unit] if @shop_item.unit.blank? && parsed_data[:unit].present?
  end

  def build_shop_item_update()
    @shop_item_update = @shop_item.shop_item_updates.build(@shop_item_update_params)

    # Calculate price_per_unit using the smart calculator
    if PricePerUnitCalculator.should_calculate?(@shop_item_update.price, @shop_item.size, @shop_item.unit)
      calculation_result = PricePerUnitCalculator.calculate_value_only(
        @shop_item_update.price,
        @shop_item.size,
        @shop_item.unit
      )

      if calculation_result
        @shop_item_update.price_per_unit = calculation_result[:price_per_unit]
        #Also store the normalized_unit if you have a field for it
        @shop_item_update.normalized_unit = calculation_result[:normalized_unit]
      end
    end
  end
end
