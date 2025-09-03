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
    
    should_create_update = last_update.nil? ||
                          last_update.price != @shop_item_update_params[:price] ||
                          last_update.stock_status != @shop_item_update_params[:stock_status]

    if should_create_update
      @shop_item_update = @shop_item.shop_item_updates.build(@shop_item_update_params)
      
      unless @shop_item_update.save
        @errors.concat(@shop_item_update.errors.full_messages)
      end
    else
      @shop_item_update = last_update
    end
  end

  def create_new_item_with_update
    @shop_item = ShopItem.new(@shop_item_params)
    
    if @shop_item.save
      @shop_item_update = @shop_item.shop_item_updates.build(@shop_item_update_params)
      
      unless @shop_item_update.save
        @errors.concat(@shop_item_update.errors.full_messages)
      end
    else
      @errors.concat(@shop_item.errors.full_messages)
    end
  end
end