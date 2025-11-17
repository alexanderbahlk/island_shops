class ScrapedShopItemBuilder < BaseShopItemBuilder
  MASSY = 'Massy'.freeze
  COSTULESS = 'Cost.U.Less'.freeze
  PRICESMART = 'PriceSmart'.freeze
  AONE = 'A1'.freeze

  # List of all traits
  ALLOWED_SCRAPE_SHOPS = [
    MASSY,
    COSTULESS,
    PRICESMART,
    AONE
  ].freeze

  def initialize(shop_item_params, shop_item_update_params)
    @shop_item_params = shop_item_params
    @shop_item_update_params = shop_item_update_params
    @errors = []
    super()
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

  def decompose
    # Clear instance variables to avoid memory leaks
    @shop_item = nil
    @shop_item_update = nil
    @shop_item_params = nil
    @shop_item_update_params = nil
    @errors = nil
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
    auto_assign_shop_item_category if @shop_item.category.nil?

    # set size and/or unit from title
    set_shop_item_size_and_unit_from_title

    # Only save if there are actual changes
    if @shop_item.changed? && !@shop_item.save
      @errors.concat(@shop_item.errors.full_messages)
      return
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
      build_shop_item_update

      @errors.concat(@shop_item_update.errors.full_messages) unless @shop_item_update.save

      remove_old_updates
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
    auto_assign_shop_item_category

    # set size and/or unit from title
    set_shop_item_size_and_unit_from_title

    if @shop_item.save
      build_shop_item_update

      @errors.concat(@shop_item_update.errors.full_messages) unless @shop_item_update.save
    else
      @errors.concat(@shop_item.errors.full_messages)
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
    return unless wrong_unit_updates.any?

    wrong_unit_updates.destroy_all
    Rails.logger.info "Removed #{wrong_unit_updates.size} ShopItemUpdates with wrong unit for ShopItem #{@shop_item.id}"
  end
end
