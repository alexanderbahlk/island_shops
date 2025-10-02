require "test_helper"

class Api::V1::ShopItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @headers = { "X-SECURE-HASH" => "gfh5haf_y6", "Content-Type" => "application/json" } # Adjust if you use a different auth mechanism

    @valid_shop_item_params = {
      shop_item: {
        url: "http://example.com/item/1",
        title: "Test Item",
        breadcrumb: "Category > Subcategory",
        image_url: "http://example.com/image.jpg",
        size: "1kg",
        unit: "kg",
        location: "Massy",
        product_id: "12345",
      },
      shop_item_update: {
        price: 9.99,
        stock_status: "in_stock",
      },
    }

    @invalid_shop_item_params = {
      shop_item: {
        url: nil, # Missing required field
        title: "Test Item",
        breadcrumb: "Category > Subcategory",
        image_url: "http://example.com/image.jpg",
        size: "1kg",
        unit: "kg",
        location: "Massy",
        product_id: "12345",
      },
      shop_item_update: {
        price: 9.99,
        stock_status: "in_stock",
      },
    }
  end

  test "should create shop item by scrape with valid params" do
    assert_difference("ShopItem.count", 1) do
      assert_difference("ShopItemUpdate.count", 1) do
        post create_by_scrape_api_v1_shop_items_path,
             params: @valid_shop_item_params,
             headers: @headers,
             as: :json

        assert_response :created
      end
    end

    response_data = JSON.parse(response.body)
    assert response_data["shop_item"]["title"] == "Test Item"
    assert response_data["shop_item_update"]["price"] == "9.99"
  end

  test "should not create shop item by scrape with invalid params" do
    assert_no_difference("ShopItem.count") do
      assert_no_difference("ShopItemUpdate.count") do
        post create_by_scrape_api_v1_shop_items_path,
             params: @invalid_shop_item_params,
             headers: @headers,
             as: :json

        assert_response :unprocessable_content
      end
    end

    response_data = JSON.parse(response.body)
    assert response_data["errors"].present?
  end
end
