require "test_helper"

class Api::V1::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_one) # Assuming you have a fixture for users
    @shopping_list = shopping_lists(:shopping_list_abc) # Assuming you have a fixture for shopping lists
    @headers = { "X-SECURE-APP-USER-HASH" => "#{@user.app_hash}", "Content-Type" => "application/json" } # Adjust if you use a different auth mechanism
  end

  test "should update group_shopping_lists_items_by with valid value" do
    patch update_group_shopping_lists_items_by_api_v1_users_path,
          params: { group_shopping_lists_items_by: "location" }.to_json,
          headers: @headers

    assert_response :ok
    response_data = JSON.parse(response.body)
    assert_equal "Group shopping lists items by updated successfully", response_data["message"]
    assert_equal "location", response_data["user"]["group_shopping_lists_items_by"]
    @user.reload
    assert_equal "location", @user.group_shopping_lists_items_by
  end

  test "should not update group_shopping_lists_items_by with invalid value" do
    patch update_group_shopping_lists_items_by_api_v1_users_path,
          params: { group_shopping_lists_items_by: "invalid_value" }.to_json,
          headers: @headers

    assert_response :unprocessable_content
    response_data = JSON.parse(response.body)
    assert_includes response_data["errors"], "Group shopping lists items by is not included in the list"
    @user.reload
    assert_equal "priority", @user.group_shopping_lists_items_by # Ensure it remains unchanged
  end

  test "should not update group_shopping_lists_items_by if user is not found" do
    patch update_group_shopping_lists_items_by_api_v1_users_path,
          params: { group_shopping_lists_items_by: "asc" }.to_json,
          headers: { "Content-Type" => "application/json" }

    assert_response :unauthorized
    response_data = JSON.parse(response.body)
    assert_equal "Unauthorized", response_data["error"]
  end

  test "should update active shopping list with valid slug" do
    patch update_active_shopping_list_api_v1_users_path,
          params: { active_shopping_list_slug: @shopping_list.slug }.to_json,
          headers: @headers

    assert_response :ok
    response_data = JSON.parse(response.body)
    assert_equal "Active shopping list updated successfully", response_data["message"]
    assert_equal @shopping_list.id, response_data["user"]["active_shopping_list_id"]
    @user.reload
    assert_equal @shopping_list.id, @user.active_shopping_list_id
  end

  test "should not update active shopping list with invalid slug" do
    patch update_active_shopping_list_api_v1_users_path,
          params: { active_shopping_list_slug: "invalid_slug" }.to_json,
          headers: @headers

    assert_response :not_found
    response_data = JSON.parse(response.body)
    assert_equal "Shopping list not found", response_data["error"]
    @user.reload
    assert_nil @user.active_shopping_list_id
  end

  test "should not update active shopping list if user is not authenticated" do
    patch update_active_shopping_list_api_v1_users_path,
          params: { active_shopping_list_slug: @shopping_list.slug }.to_json,
          headers: { "Content-Type" => "application/json" }

    assert_response :unauthorized
    response_data = JSON.parse(response.body)
    assert_equal "Unauthorized", response_data["error"]
    @user.reload
    assert_nil @user.active_shopping_list_id
  end
end
