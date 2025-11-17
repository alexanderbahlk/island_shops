class AppShopItemBuilder < BaseShopItemBuilder
  attr_reader :place

  def initialize(shop_item_params, shop_item_update_params, place_params, add_to_active_shopping_list_param)
    @shop_item_params = shop_item_params
    @shop_item_update_params = shop_item_update_params
    @place_params = place_params
    @user = shop_item_params[:user]
    @add_to_active_shopping_list_param = add_to_active_shopping_list_param
    @errors = []
    super()
  end

  def build
    create_new_shop_item_with_shop_item_update
    add_shop_item_to_user_active_shopping_list if success? && @add_to_active_shopping_list_param
    success?
  end

  def success?
    @errors.empty?
  end

  private

  # Creates a new ShopItem record along with an associated ShopItemUpdate.
  #
  # This method performs the following operations:
  # 1. Sets up the shop item parameters by creating a URL, marking as approved, and finding/creating a place
  # 2. Initializes a new ShopItem instance
  # 3. Auto-assigns a category to the shop item
  # 4. Extracts and sets size/unit information from the title
  # 5. Saves the shop item and creates an associated shop item update
  # 6. Collects any validation errors from either the shop item or shop item update
  #
  # @return [void]
  # @note Populates @errors array with any validation errors encountered during save operations
  # @note Modifies @shop_item_params by adding :url, :approved, and :place keys
  # @note Creates @shop_item and @shop_item_update instance variables
  def create_new_shop_item_with_shop_item_update
    @shop_item_params[:url] = create_url
    @shop_item_params[:approved] = true
    @shop_item_params[:place] = find_or_create_place

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

  # Adds a shop item to the user's active shopping list.
  #
  # This method ensures the user has an active shopping list (creating one if necessary),
  # then builds and saves a new shopping list item with the shop item details.
  #
  # The shopping list item is created with:
  # - title: from the shop item
  # - shop_item: reference to the shop item
  # - category: from the shop item (or nil if not present)
  # - quantity: defaults to 1
  # - user: reference to the current user
  #
  # @return [void]
  # @note If the user has no active shopping list and one cannot be created,
  #   an error message is added to @errors and the method returns early.
  # @note If the shopping list item fails to save, validation errors are
  #   appended to @errors.
  def add_shop_item_to_user_active_shopping_list
    active_shopping_list = @user.active_shopping_list
    if active_shopping_list.nil?
      create_first_active_shopping_list_for_user
      active_shopping_list = @user.active_shopping_list
      if active_shopping_list.nil?
        @errors << 'User has no active shopping list'
        return
      end
    end

    # Build the ShoppingListItem
    shopping_list_item = active_shopping_list.shopping_list_items.build(
      title: @shop_item.title,
      shop_item: @shop_item,
      category: @shop_item.category || nil,
      quantity: 1,
      user: @user
    )

    return if shopping_list_item.save

    @errors.concat(shopping_list_item.errors.full_messages)
  end

  def create_first_active_shopping_list_for_user
    shopping_list = ShoppingList.new(display_name: 'First Shopping List', shopping_list_items: [])
    shopping_list.users << @user
    if shopping_list.save
      @user.update(active_shopping_list: shopping_list)
    else
      @errors.concat(shopping_list.errors.full_messages)
    end
  end

  def create_url
    base_url = 'https://island-shops-56ja3.ondigitalocean.app/shop_item/'.freeze
    # test for @shop_item_params[:title] first
    if @shop_item_params[:title].blank?
      @errors << "Title can't be blank"
      return
    end

    base_slug = @shop_item_params[:title].parameterize
    base_url + "#{base_slug}-#{DateTime.now.to_i}"
  end

  def find_or_create_place
    place = fuzzy_find_place_by_latitude_longitude
    return place if place.present?

    place = fuzzy_match_find_or_create_place
    if place.nil?
      place = Place.new(@place_params)
      @errors.concat(place.errors.full_messages) unless place.save
    end
    place
  end

  def fuzzy_find_place_by_latitude_longitude
    service = Places::FuzzyFindPlaceByLatitudeLongitudeService.new(place_params: @place_params)
    place = service.call
    @errors.concat(service.errors) if service.errors.any?
    place
  end

  def fuzzy_match_find_or_create_place
    service = Places::FuzzyFindPlaceByTitleLocationService.new(place_params: @place_params)
    place = service.call
    @errors.concat(service.errors) if service.errors.any?
    place
  end
end
