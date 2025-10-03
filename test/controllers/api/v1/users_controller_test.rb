require "test_helper"

class Api::V1::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_one) # Assuming you have a fixture for users
    @headers = { "X-SECURE-APP-USER-HASH" => "#{@user.app_hash}", "Content-Type" => "application/json" } # Adjust if you use a different auth mechanism
  end

  test "should update sorting_order with valid value" do
    patch update_sorting_order_api_v1_users_path,
          params: { sorting_order: "location" }.to_json,
          headers: @headers

    assert_response :ok
    response_data = JSON.parse(response.body)
    assert_equal "Sorting order updated successfully", response_data["message"]
    assert_equal "location", response_data["user"]["sorting_order"]
    @user.reload
    assert_equal "location", @user.sorting_order
  end

  test "should not update sorting_order with invalid value" do
    patch update_sorting_order_api_v1_users_path,
          params: { sorting_order: "invalid_value" }.to_json,
          headers: @headers

    assert_response :unprocessable_content
    response_data = JSON.parse(response.body)
    assert_includes response_data["errors"], "Sorting order is not included in the list"
    @user.reload
    assert_equal "priority", @user.sorting_order
  end

  test "should not update sorting_order if user is not found" do
    patch update_sorting_order_api_v1_users_path,
          params: { sorting_order: "asc" }.to_json,
          headers: { "Content-Type" => "application/json" }

    assert_response :unauthorized
    response_data = JSON.parse(response.body)
    assert_equal "Unauthorized", response_data["error"]
  end
end
