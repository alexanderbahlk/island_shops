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
      build_shop_item_update(@shop_item.size)

      unless @shop_item_update.save
        @errors.concat(@shop_item_update.errors.full_messages)
      end
    else
      @shop_item_update = last_update
    end
  end

  def create_new_item_with_update
    @shop_item = ShopItem.new(@shop_item_params)

    # set size from title if size is missing
    if @shop_item.size.blank? && @shop_item.title.present?
      set_shop_item_size_from_title()
    end

    if @shop_item.save
      build_shop_item_update(@shop_item.size)

      unless @shop_item_update.save
        @errors.concat(@shop_item_update.errors.full_messages)
      end
    else
      @errors.concat(@shop_item.errors.full_messages)
    end
  end

  def set_shop_item_size_from_title
    return if @shop_item.title.blank?

    #check if last elements of title is a number or decimel
    # e.g. "Badia Garlic Powder 16"

    #check if last elements of title has Ct

    #check if last elements of title has pack

    #check if last elements of title has pcs

    #check if last elements of title has EACH or [EACH]

    #check if last elements of title has g

    #check if last elements of title has Gr

    #check if last elements of title has Kg

    #check if last elements of title has kg

    #check if last elements of title has L

    #check if last elements of title has ml

    #check if last elements of title has Ml

    #check if last elements of title has Oz

    #check if last elements of title has oz

    #check if last elements of title has Fl

    #check if last elements of title has fl

  end

  def build_shop_item_update(size)
    @shop_item_update = @shop_item.shop_item_updates.build(@shop_item_update_params)
  end
end
