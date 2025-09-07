require "test_helper"

#run 'rails db:test:prepare' for missing migration

class ShopItemBuilderTest < ActiveSupport::TestCase
  def setup
    @shop_item_params = {
      url: "https://example.com/item/123",
      shop: "Massy",
      title: "Test Item",
      size: "M",
    }

    @shop_item_update_params = {
      price: 29.99,
      stock_status: "in_stock",
    }
  end

  test "creates new shop item with update when item doesn't exist" do
    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)

    assert_difference ["ShopItem.count", "ShopItemUpdate.count"], 1 do
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

    assert_difference "ShopItemUpdate.count", 1 do
      assert_no_difference "ShopItem.count" do
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

    assert_no_difference "ShopItemUpdate.count" do
      result = builder.build
      assert result
    end

    assert_equal last_update, builder.shop_item_update
  end

  test "handles validation errors for shop item" do
    @shop_item_params[:url] = nil # assuming url is required

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)

    assert_no_difference ["ShopItem.count", "ShopItemUpdate.count"] do
      result = builder.build
      refute result
    end

    refute builder.errors.empty?
  end

  test "handles validation errors for shop item update" do
    @shop_item_update_params[:price] = nil # assuming price is required

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)

    assert_difference "ShopItem.count", 1 do
      assert_no_difference "ShopItemUpdate.count" do
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

  # Tests for set_shop_item_size_and_unit_from_title method
  test "extracts size and unit from title with ct (count) - with space" do
    @shop_item_params[:title] = "Toufayan Bagels Blueberry 16 Ct"
    @shop_item_params[:size] = nil # Ensure size is blank to trigger extraction

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 16.0, builder.shop_item.size
    assert_equal "ct", builder.shop_item.unit
  end

  test "extracts size and unit from title and params with lt" do
    @shop_item_params[:title] = "Sungold Evaporated Milk"
    @shop_item_params[:size] = 1 # Ensure size is blank to trigger extraction
    @shop_item_params[:unit] = "lt" # Ensure size is blank to trigger extraction

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 1.0, builder.shop_item.size
    assert_equal "l", builder.shop_item.unit
  end

  test "extracts size and unit from title and params with pk" do
    @shop_item_params[:title] = "Good Time Mix Tray Nuts 12 Pk"
    @shop_item_params[:size] = 12 # Ensure size is blank to trigger extraction
    @shop_item_params[:unit] = "pk" # Ensure size is blank to trigger extraction

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 12.0, builder.shop_item.size
    assert_equal "pc", builder.shop_item.unit
  end

  test "extracts size and unit from title with ct (count) - without space" do
    @shop_item_params[:title] = "Toufayan Bagels Blueberry 16Ct"
    @shop_item_params[:size] = nil

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 16.0, builder.shop_item.size
    assert_equal "ct", builder.shop_item.unit
  end

  test "extracts size and unit from title with lbs - without space" do
    @shop_item_params[:title] = "Badia Garlic Powder 2lbs"
    @shop_item_params[:size] = nil

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 2.0, builder.shop_item.size
    assert_equal "lbs", builder.shop_item.unit
  end

  test "extracts size and unit from title with lb - with space" do
    @shop_item_params[:title] = "Badia Garlic Powder 2 lb"
    @shop_item_params[:size] = nil

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 2.0, builder.shop_item.size
    assert_equal "lbs", builder.shop_item.unit
  end

  test "extracts size and unit from title with grams - with space" do
    @shop_item_params[:title] = "Badia Garlic Powder 200 g"
    @shop_item_params[:size] = nil

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 200.0, builder.shop_item.size
    assert_equal "g", builder.shop_item.unit
  end

  test "extracts size and unit from title with grams - without space" do
    @shop_item_params[:title] = "Badia Garlic Powder 200g"
    @shop_item_params[:size] = nil

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 200.0, builder.shop_item.size
    assert_equal "g", builder.shop_item.unit
  end

  test "extracts size and unit from title with Gr (grams variant)" do
    @shop_item_params[:title] = "Badia Garlic Powder 200Gr"
    @shop_item_params[:size] = nil

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 200.0, builder.shop_item.size
    assert_equal "g", builder.shop_item.unit
  end

  test "extracts size and unit from title with kilograms" do
    @shop_item_params[:title] = "Rice Bag 5Kg"
    @shop_item_params[:size] = nil

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 5.0, builder.shop_item.size
    assert_equal "kg", builder.shop_item.unit
  end

  test "extracts size and unit from title with liters" do
    @shop_item_params[:title] = "Cooking Oil 2L"
    @shop_item_params[:size] = nil

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 2.0, builder.shop_item.size
    assert_equal "l", builder.shop_item.unit
  end

  test "extracts size and unit from title with milliliters" do
    @shop_item_params[:title] = "Vanilla Extract 250ml"
    @shop_item_params[:size] = nil

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 250.0, builder.shop_item.size
    assert_equal "ml", builder.shop_item.unit
  end

  test "extracts size and unit from title with ounces" do
    @shop_item_params[:title] = "Cereal Box 12Oz"
    @shop_item_params[:size] = nil

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 12.0, builder.shop_item.size
    assert_equal "oz", builder.shop_item.unit
  end

  test "extracts size and unit from title with fl (fluid ounces)" do
    @shop_item_params[:title] = "Bottle Water 16Fl"
    @shop_item_params[:size] = nil

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 16.0, builder.shop_item.size
    assert_equal "fl", builder.shop_item.unit
  end

  test "extracts size and unit from title with pack" do
    @shop_item_params[:title] = "Chocolate Bars 6pack"
    @shop_item_params[:size] = nil

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 6.0, builder.shop_item.size
    assert_equal "pc", builder.shop_item.unit
  end

  test "extracts size and unit from title with pcs (pieces)" do
    @shop_item_params[:title] = "Chicken Wings 10pcs"
    @shop_item_params[:size] = nil

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 10.0, builder.shop_item.size
    assert_equal "pc", builder.shop_item.unit
  end

  test "extracts size and unit from title with EACH" do
    @shop_item_params[:title] = "Apple 1EACH"
    @shop_item_params[:size] = nil

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 1.0, builder.shop_item.size
    assert_equal "each", builder.shop_item.unit
  end

  test "extracts size and unit from title with [EACH]" do
    @shop_item_params[:title] = "Banana 1[EACH]"
    @shop_item_params[:size] = nil

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 1.0, builder.shop_item.size
    assert_equal "each", builder.shop_item.unit
  end

  test "created category" do
    @shop_item_params[:title] = "Bag of Tomatos"
    @shop_item_params[:size] = nil

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_nil builder.shop_item.size
    assert_nil builder.shop_item.unit
    assert_equal "Tomatoes", builder.shop_item.category.title
  end

  test "extracts decimal size from title" do
    @shop_item_params[:title] = "Milk Carton 2.5L"
    @shop_item_params[:size] = nil

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 2.5, builder.shop_item.size
    assert_equal "l", builder.shop_item.unit
  end

  test "extracts plain number with N/A unit" do
    @shop_item_params[:title] = "Generic Item 42"
    @shop_item_params[:size] = nil

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 42.0, builder.shop_item.size
    assert_equal "N/A", builder.shop_item.unit
  end

  test "case insensitive matching works" do
    @shop_item_params[:title] = "Test Item 5ct"
    @shop_item_params[:size] = nil

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 5.0, builder.shop_item.size
    assert_equal "ct", builder.shop_item.unit
  end

  test "does not extract when title has no numeric ending" do
    @shop_item_params[:title] = "Generic Product Name"
    @shop_item_params[:size] = nil

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_nil builder.shop_item.size
    assert_nil builder.shop_item.unit
  end

  test "does not extract when title is blank" do
    @shop_item_params[:title] = ""
    @shop_item_params[:size] = nil

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_nil builder.shop_item.size
    assert_nil builder.shop_item.unit
  end

  test "does not extract when size and unit already exists" do
    @shop_item_params[:title] = "Test Item 500Gr"
    @shop_item_params[:size] = 400.0 # Size already provided
    @shop_item_params[:unit] = "g" # Unit already provided

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 400.0, builder.shop_item.size # Original size preserved
    assert_equal "g", builder.shop_item.unit # Original unit preserved
  end

  test "prioritizes first matching pattern - ct over plain number" do
    @shop_item_params[:title] = "Item 16 Ct"
    @shop_item_params[:size] = nil

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 16.0, builder.shop_item.size
    assert_equal "ct", builder.shop_item.unit # Should be "ct", not "N/A"
  end

  test "handles complex title with multiple numbers" do
    @shop_item_params[:title] = "Product 2023 Edition 500g"
    @shop_item_params[:size] = nil

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    assert_equal 500.0, builder.shop_item.size
    assert_equal "g", builder.shop_item.unit
  end

  test "create correct category from breadcrumb params" do
    @shop_item_params[:title] = "Sungold Evaporated Milk"
    @shop_item_params[:breadcrumb] = "Shop / Grocery / Beverages / Milks , Evaporated, Condensed , Powdered, Shelf Stable / Sungold Evaporated Milk"
    @shop_item_params[:size] = 1 # Ensure size is blank to trigger extraction
    @shop_item_params[:unit] = "lt" # Ensure size is blank to trigger extraction

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    @evaporated_milk_category = categories(:evaporated_milk)
    assert_equal @evaporated_milk_category, builder.shop_item.category
  end

  test "create correct category from title params" do
    @shop_item_params[:title] = "Sungold Milk"
    @shop_item_params[:size] = 1 # Ensure size is blank to trigger extraction
    @shop_item_params[:unit] = "lt" # Ensure size is blank to trigger extraction

    builder = ShopItemBuilder.new(@shop_item_params, @shop_item_update_params)
    builder.build

    @milk_category = categories(:milk)
    assert_equal @milk_category, builder.shop_item.category
  end
end
