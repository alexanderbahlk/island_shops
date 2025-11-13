class AppShopItemBuilder < BaseShopItemBuilder
  attr_reader :place

  def initialize(shop_item_params, shop_item_update_params, place_params, add_to_active_shopping_list_param)
    @shop_item_params = shop_item_params
    @shop_item_update_params = shop_item_update_params
    @place_params = place_params
    @user = shop_item_params[:user]
    @add_to_active_shopping_list_param = add_to_active_shopping_list_param
    @errors = []
  end

  def build
    create_new_shop_item_with_shop_item_update
    if success? && @add_to_active_shopping_list_param
      add_shop_item_to_user_active_shopping_list
    end
    success?
  end

  def success?
    @errors.empty?
  end

  private

  def create_new_shop_item_with_shop_item_update
    @shop_item_params[:url] = create_url
    @shop_item_params[:approved] = true
    @shop_item_params[:place] = find_or_create_place

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

  def add_shop_item_to_user_active_shopping_list
    active_shopping_list = @user.active_shopping_list
    if active_shopping_list.nil?
      create_first_active_shopping_list_for_user
      active_shopping_list = @user.active_shopping_list
      if active_shopping_list.nil?
        @errors << "User has no active shopping list"
        return
      end
    end

    # Build the ShoppingListItem
    shopping_list_item = active_shopping_list.shopping_list_items.build(
      title: @shop_item.title,
      shop_item: @shop_item,
      category: @shop_item.category || nil,
      quantity: 1,
      user: @user,
    )

    unless shopping_list_item.save
      @errors.concat(shopping_list_item.errors.full_messages)
    end
  end

  def create_first_active_shopping_list_for_user
    shopping_list = ShoppingList.new(display_name: "First Shopping List", shopping_list_items: [])
    shopping_list.users << @user
    if shopping_list.save
      @user.update(active_shopping_list: shopping_list)
    else
      @errors.concat(shopping_list.errors.full_messages)
    end
  end

  def create_url
    base_url = "https://island-shops-56ja3.ondigitalocean.app/shop_item/".freeze
    # test for @shop_item_params[:title] first
    if @shop_item_params[:title].blank?
      @errors << "Title can't be blank"
      return
    end

    base_slug = @shop_item_params[:title].parameterize
    url = base_url + "#{base_slug}-#{DateTime.now.to_i}"
    url
  end

  def find_or_create_place
    place = fuzzy_find_place_by_latitude_longitude
    return place if place.present?

    place = fuzzy_match_find_or_create_place
    if place.nil?
      place = Place.new(@place_params)
      unless place.save
        @errors.concat(place.errors.full_messages)
      end
    end
    place
  end

  def fuzzy_find_place_by_latitude_longitude
    service = Places::FuzzyFindPlaceByLatitudeLongitudeService.new(place_params: @place_params)
    place = service.call
    if service.errors.any?
      @errors.concat(service.errors)
    end
    place
  end

  def fuzzy_match_find_or_create_place
    service = Places::FuzzyFindPlaceByTitleLocationService.new(place_params: @place_params)
    place = service.call
    if service.errors.any?
      @errors.concat(service.errors)
    end
    place
  end
end
