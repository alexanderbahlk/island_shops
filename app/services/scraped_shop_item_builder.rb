class ScrapedShopItemBuilder
  attr_reader :shop_item, :shop_item_update, :errors

  MASSY = "Massy".freeze
  COSTULESS = "Cost.U.Less".freeze
  PRICESMART = "PriceSmart".freeze
  AONE = "A1".freeze

  # List of all traits
  ALLOWED_SCRAPE_SHOPS = [
    MASSY,
    COSTULESS,
    PRICESMART,
    AONE,
  ].freeze

  def initialize(shop_item_params, shop_item_update_params)
    @shop_item_params = shop_item_params
    @shop_item_update_params = shop_item_update_params
    @errors = []
  end

  def build
    existing_shop_item = ShopItem.find_by(url: @shop_item_params[:url])

    if existing_shop_item
      create_shop_item_update_for_existing_shop_item(existing_shop_item)
    else
      create_new_shop_item_with_shop_item_update
    end

    success?
  end

  def success?
    @errors.empty?
  end

  private

  def create_shop_item_update_for_existing_shop_item(existing_item)
    @shop_item = existing_item

    if @shop_item.approved
      # Avoid changing the ID, size, or unit of the existing item
      @shop_item.assign_attributes(@shop_item_params.except(:id, :size, :unit, :place))
    else
      # If not approved, allow updating size and unit as well
      @shop_item.assign_attributes(@shop_item_params.except(:id, :place))
    end
    # Auto-assign category if not already set
    auto_assign_shop_item_category() if @shop_item.category.nil?

    # set size and/or unit from title
    set_shop_item_size_and_unit_from_title()

    # Only save if there are actual changes
    if @shop_item.changed?
      unless @shop_item.save
        @errors.concat(@shop_item.errors.full_messages)
        return
      end
    end

    # Check if we need to create an update based on changes
    last_update = @shop_item.shop_item_updates.order(:created_at).last

    Rails.logger.debug "Last update: #{last_update.inspect}"

    should_create_update = last_update.nil? ||
                           last_update.price_per_unit.nil? ||
                           @shop_item.approved == false ||
                           last_update.price != @shop_item_update_params[:price] ||
                           last_update.stock_status != @shop_item_update_params[:stock_status]

    Rails.logger.debug "Should create update: #{should_create_update}"

    if should_create_update
      build_shop_item_update()

      unless @shop_item_update.save
        @errors.concat(@shop_item_update.errors.full_messages)
      end

      remove_old_updates()
    else
      @shop_item_update = last_update
    end
  end

  def create_new_shop_item_with_shop_item_update
    location_string = @shop_item_params.delete(:place)

    # stop if location_string is nill or not in ALLOWED_SCRAPE_SHOPS
    if location_string && ALLOWED_SCRAPE_SHOPS.include?(location_string.strip)
      place = Place.find_or_create_by(title: location_string.strip)
      @shop_item_params[:place] = place
    else
      @errors << "Invalid or missing place: #{location_string}"
      return
    end

    @shop_item = ShopItem.new(@shop_item_params)

    # Auto-assign category for new items
    auto_assign_shop_item_category()

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

  def auto_assign_shop_item_category
    return if @shop_item.title.blank?

    # Try to find the best matching category
    best_match = ShopItemCategoryMatcher.new(shop_item: @shop_item).find_best_match()

    if best_match
      @shop_item.category = best_match
      @category_match_info = {
        matched: true,
        category: best_match.title,
        similarity: best_match.respond_to?(:sim_score) ? best_match.sim_score : nil,
        method: "fuzzy_match",
      }

      Rails.logger.info "Auto-assigned ShopItemType '#{best_match.title}' to '#{@shop_item.title}'"
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

  def remove_old_updates
    updates_to_keep = 5
    # Keep only the latest 5 updates
    old_updates = @shop_item.shop_item_updates.order(created_at: :desc).offset(updates_to_keep)

    if old_updates.any?
      old_updates.destroy_all
      Rails.logger.info "Removed #{old_updates.size} old ShopItemUpdates for ShopItem #{@shop_item.id}"
    end

    wrong_unit_updates = @shop_item.shop_item_updates.where.not(normalized_unit: @shop_item_update.normalized_unit)
    if wrong_unit_updates.any?
      wrong_unit_updates.destroy_all
      Rails.logger.info "Removed #{wrong_unit_updates.size} ShopItemUpdates with wrong unit for ShopItem #{@shop_item.id}"
    end
  end
end
