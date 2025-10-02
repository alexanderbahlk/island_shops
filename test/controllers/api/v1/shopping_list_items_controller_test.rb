require "test_helper"

class Api::V1::ShoppingListItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_one) # Assuming you have a fixture for users
    @shopping_list = shopping_lists(:shopping_list_abc) # Assuming you have a fixture for shopping lists
    @shopping_list_item = shopping_list_items(:shopping_list_item_milk) # Assuming you have a fixture for shopping list items
    @shop_item = shop_items(:shop_item_one) # Assuming you have a fixture for shop items

    @headers = { "X-SECURE-APP-USER-HASH" => "#{@user.app_hash}", "Content-Type" => "application/json" } # Adjust if you use a different auth mechanism
  end

  test "should update quantity" do
    patch api_v1_shopping_list_item_path(@shopping_list_item.uuid),
          params: { shopping_list_item: { quantity: 5 } }.to_json,
          headers: @headers

    assert_response :success
    @shopping_list_item.reload
    assert_equal 5, @shopping_list_item.quantity
  end

  test "should update priority" do
    patch api_v1_shopping_list_item_path(@shopping_list_item.uuid),
          params: { shopping_list_item: { priority: true } }.to_json,
          headers: @headers

    assert_response :success
    @shopping_list_item.reload
    assert @shopping_list_item.priority
  end

  test "should update purchased" do
    patch api_v1_shopping_list_item_path(@shopping_list_item.uuid),
          params: { shopping_list_item: { purchased: true } }.to_json,
          headers: @headers

    assert_response :success
    @shopping_list_item.reload
    assert @shopping_list_item.purchased
  end

  test "should update shop_item_uuid" do
    patch api_v1_shopping_list_item_path(@shopping_list_item.uuid),
          params: { shopping_list_item: { purchased: true }, shop_item: { uuid: @shop_item.uuid } }.to_json,
          headers: @headers

    assert_response :success
    @shopping_list_item.reload
    assert_equal @shop_item.id, @shopping_list_item.shop_item_id
  end
end
