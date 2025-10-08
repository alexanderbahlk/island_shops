require "test_helper"

class Api::V1::ShoppingListsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_one) # Assuming you have a fixture for users
    @shopping_list = shopping_lists(:shopping_list_abc) # Assuming you have a fixture for shopping lists
    @headers = { "X-SECURE-APP-USER-HASH" => @user.app_hash, "Content-Type" => "application/json" }
  end

  # Test for the `show` action
  test "should show shopping list" do
    get api_v1_shopping_list_path(@shopping_list.slug), headers: @headers

    assert_response :success
    response_data = JSON.parse(response.body)

    # Ensure the response includes the correct keys
    assert response_data["shopping_list_items"].key?("unpurchased"), "Response is missing the 'unpurchased' key"
    assert response_data["shopping_list_items"].key?("purchased"), "Response is missing the 'purchased' key"

    # Ensure the items are grouped correctly
    assert_equal ["Cheese", "Milk 2x"], response_data["shopping_list_items"]["unpurchased"].map { |item| item["title"] }
    assert_equal ["Goat Cheese"], response_data["shopping_list_items"]["purchased"].map { |item| item["title"] }

    # Ensure other attributes are present
    assert_equal @shopping_list.slug, response_data["slug"]
    assert_equal @shopping_list.display_name, response_data["display_name"]

    # Test that the key exists and its value is nil
    assert response_data.key?("group_shopping_lists_items_by"), "Response is missing the 'group_shopping_lists_items_by' key"
    assert_nil response_data["group_shopping_lists_items_by"], "'group_shopping_lists_items_by' should be nil"

    assert_equal @shopping_list.shopping_list_items.count, response_data["shopping_list_items_count"]
    assert_equal @shopping_list.shopping_list_items.purchased.count, response_data["shopping_list_items_purchased_count"]
  end

  # Test for the `create` action
  test "should create shopping list" do
    assert_difference("ShoppingList.count", 1) do
      post api_v1_shopping_lists_path,
           params: { display_name: "New Shopping List" }.to_json,
           headers: @headers

      assert_response :created
    end

    response_data = JSON.parse(response.body)
    assert_equal "New Shopping List", response_data["display_name"]
    assert response_data["slug"].present?
  end

  test "should not create shopping list with invalid params" do
    assert_no_difference("ShoppingList.count") do
      post api_v1_shopping_lists_path,
           params: { display_name: "" }.to_json,
           headers: @headers

      assert_response :unprocessable_content
    end

    response_data = JSON.parse(response.body)
    assert_includes response_data["errors"], "Display name can't be blank"
  end

  # Test for the `update` action
  test "should update shopping list" do
    patch api_v1_shopping_list_path(@shopping_list.slug),
          params: { shopping_list: { display_name: "Updated Name" } }.to_json,
          headers: @headers

    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "Updated Name", response_data["display_name"]
    @shopping_list.reload
    assert_equal "Updated Name", @shopping_list.display_name
  end

  test "should not update shopping list with invalid params" do
    patch api_v1_shopping_list_path(@shopping_list.slug),
          params: { shopping_list: { display_name: "" } }.to_json,
          headers: @headers

    assert_response :unprocessable_content
    response_data = JSON.parse(response.body)
    assert_includes response_data["errors"], "Display name can't be blank"
    @shopping_list.reload
    assert_not_equal "", @shopping_list.display_name
  end

  # Test for the `destroy` action
  test "should destroy shopping list" do
    @user.update(active_shopping_list: @shopping_list)

    assert_difference("ShoppingList.count", -1) do
      delete api_v1_shopping_list_path(@shopping_list.slug), headers: @headers

      assert_response :ok
    end

    response_data = JSON.parse(response.body)
    assert_equal @shopping_list.slug, response_data["slug"]
  end

  test "should return not found for non-existent shopping list" do
    get api_v1_shopping_list_path("non-existent-slug"), headers: @headers

    assert_response :not_found
    response_data = JSON.parse(response.body)
    assert_equal "ShoppingList not found", response_data["error"]
  end
end
