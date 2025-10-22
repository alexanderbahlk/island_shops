require "test_helper"

class Api::V1::ShopItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_one) # Assuming you have a fixture for users
    @headers = { "X-SECURE-APP-USER-HASH" => "#{@user.app_hash}", "Content-Type" => "application/json" } # Adjust if you use a different auth mechanism

    @valid_shop_item_existing_place_params = {
      shop_item: {
        title: "Coconutwater",
        size: 1.0,
        unit: "gal",
      },
      shop_item_update: {
        price: 17.0,
      },
      place: {
        title: "Coconutwater truck",
        location: "3F85+X7W, Oistins, Christ Church",
      },
    }

    @valid_shop_item_new_place_params = {
      shop_item: {
        title: "Coconutwater",
        size: 1.0,
        unit: "gal",
      },
      shop_item_update: {
        price: 17.0,
      },
      place: {
        title: "Coconutwater truck",
        location: "3F85+X7E, Oistins, Christ Church",
      },
    }

    @invalid_shop_item_params = {
      shop_item: {
        title: nil,
        size: 1.0,
        unit: "gal",
      },
      shop_item_update: {
        price: 17.0,
      },
      place: {
        title: "Coconutwater truck",
        location: "3F85+X7W, Oistins, Christ Church",
      },
    }
  end

  test "should create shop item with existing place with user by app with valid params" do
    assert_difference("ShopItem.count", 1) do
      assert_difference("ShopItemUpdate.count", 1) do
        post api_v1_shop_items_path,
             params: @valid_shop_item_existing_place_params,
             headers: @headers,
             as: :json

        assert_response :created
      end
    end

    existing_place = places(:place_three)
    response_data = JSON.parse(response.body)
    assert response_data["shop_item"]["title"] == "Coconutwater"
    assert response_data["shop_item_update"]["price"] == "17.0"
    assert_equal existing_place.id, response_data["shop_item"]["place_id"]
    assert_equal @user.id, response_data["shop_item"]["user_id"]
  end

  test "should create shop item with new place by app with valid params" do
    assert_difference("ShopItem.count", 1) do
      assert_difference("ShopItemUpdate.count", 1) do
        post api_v1_shop_items_path,
             params: @valid_shop_item_new_place_params,
             headers: @headers,
             as: :json

        assert_response :created
      end
    end

    existing_place = places(:place_three)
    response_data = JSON.parse(response.body)
    assert response_data["shop_item"]["title"] == "Coconutwater"
    assert response_data["shop_item_update"]["price"] == "17.0"
    assert response_data["shop_item_update"]["normalized_unit"] == "100ml"
    assert_not_equal existing_place.id, response_data["shop_item"]["place_id"]
  end

  test "should create shop item with with one watermelon" do
    watermellon_place_params = {
      shop_item: {
        title: "Watermelon",
        size: 1.0,
        unit: "each",
      },
      shop_item_update: {
        price: 5.0,
      },
      place: {
        title: "Fruit Stand",
        location: "3F85+X7H, Oistins, Christ Church",
      },
    }
    assert_difference("ShopItem.count", 1) do
      assert_difference("ShopItemUpdate.count", 1) do
        post api_v1_shop_items_path,
             params: watermellon_place_params,
             headers: @headers,
             as: :json

        assert_response :created
      end
    end
    response_data = JSON.parse(response.body)
    assert response_data["shop_item"]["title"] == "Watermelon"
    assert response_data["shop_item_update"]["price"] == "5.0"
    assert response_data["shop_item_update"]["normalized_unit"] == "each"
  end

  test "should not create shop item by scrape with invalid params" do
    assert_no_difference("ShopItem.count") do
      assert_no_difference("ShopItemUpdate.count") do
        post api_v1_shop_items_path,
             params: @invalid_shop_item_params,
             headers: @headers,
             as: :json

        assert_response :unprocessable_content
      end
    end

    response_data = JSON.parse(response.body)
    assert response_data["errors"].present?
    assert response_data["errors"].include?("Title can't be blank")
  end
end
