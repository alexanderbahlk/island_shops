require 'test_helper'

class ShopItemBuilderTest < ActiveSupport::TestCase
  def setup
    @shop_item_params = {
      url: 'https://example.com/item/123',
      shop: 'Massy',
      title: 'Test Item',
      size: 'M'
    }
    
    @shop_item_update_params = {
      price: 29.99,
      stock_status: 'in_stock'
    }
  end

  test "creates new shop item with update when item doesn't exist" do
    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    
    assert_difference ['ShopItem.count', 'ShopItemUpdate.count'], 1 do
      result = builder.build
      assert result
    end
    
    assert_equal @shop_item_params[:url], builder.shop_item.url
    assert_equal @shop_item_params[:title], builder.shop_item.title
    assert_equal @shop_item_params[:shop], builder.shop_item.shop
    assert_equal @shop_item_update_params[:price], builder.shop_item_update.price
    assert_equal @shop_item_update_params[:stock_status], builder.shop_item_update.stock_status
  end

  test "creates update for existing item when data changes" do
    existing_item = shop_items(:shop_item_one)
    @shop_item_params[:url] = existing_item.url
    
    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    
    assert_difference 'ShopItemUpdate.count', 1 do
      assert_no_difference 'ShopItem.count' do
        result = builder.build
        assert result
      end
    end
    
    assert_equal existing_item, builder.shop_item
    assert_equal @shop_item_update_params[:price], builder.shop_item_update.price
  end

  test "doesn't create update when data hasn't changed" do
    existing_item = shop_items(:shop_item_one)
    last_update = shop_item_updates(:shop_item_update_one)
    @shop_item_params[:url] = existing_item.url
    @shop_item_update_params[:price] = last_update.price
    @shop_item_update_params[:stock_status] = last_update.stock_status
    
    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    
    assert_no_difference 'ShopItemUpdate.count' do
      result = builder.build
      assert result
    end
    
    assert_equal last_update, builder.shop_item_update
  end

  test "handles validation errors for shop item" do
    @shop_item_params[:url] = nil # assuming url is required
    
    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    
    assert_no_difference ['ShopItem.count', 'ShopItemUpdate.count'] do
      result = builder.build
      refute result
    end
    
    refute builder.errors.empty?
  end

  test "handles validation errors for shop item update" do
    @shop_item_update_params[:price] = nil # assuming price is required
    
    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    
    assert_difference 'ShopItem.count', 1 do
      assert_no_difference 'ShopItemUpdate.count' do
        result = builder.build
        refute result
      end
    end
    
    refute builder.errors.empty?
  end

  test "success? returns true when no errors" do
    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build
    
    assert builder.success?
  end

  test "success? returns false when errors exist" do
    @shop_item_params[:url] = nil
    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build
    
    refute builder.success?
  end
end