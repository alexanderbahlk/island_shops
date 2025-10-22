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
    @shop_item_params[:place] = fuzzy_match_find_or_create_place

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
      @errors << "User has no active shopping list"
      return
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

  def fuzzy_match_find_or_create_place
    location = @place_params[:location]
    title = @place_params[:title]
    sanitized_place_title = ActiveRecord::Base.connection.quote(title)

    similarity_threshold = 0.8 # Adjust this value between 0.0 and 1.0

    # Ensure the pg_trgm extension is enabled
    ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")

    cache_key = "fuzzy_match_place/#{title}/#{location}"
    Rails.cache.fetch(cache_key, expires_in: 1.seconds) do

      # Perform a fuzzy search using similarity
      sql = <<~SQL
              SELECT  *, 
                      GREATEST(
                        similarity(places.title, #{sanitized_place_title})
                    ) as sim_score
        FROM places
        WHERE GREATEST(
                similarity(places.title, #{sanitized_place_title})
              ) >= #{similarity_threshold}
        ORDER BY sim_score DESC
        LIMIT 10
      SQL

      results = ActiveRecord::Base.connection.exec_query(sql)

      #check if in any of the results the location matches and store the first one found in one variable

      matching_results = results.to_a.select { |row| row["location"] == location }
      if matching_results.any?
        @place = Place.find(matching_results.first["id"])
      else
        @place = Place.new(title: title, location: location)
        unless @place.save
          @errors.concat(@place.errors.full_messages)
        end
      end
      @place
    end
  end
end
