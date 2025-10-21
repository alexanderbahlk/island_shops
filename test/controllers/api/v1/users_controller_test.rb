require "test_helper"

class Api::V1::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_one) # Assuming you have a fixture for users
    @shopping_list = shopping_lists(:shopping_list_abc) # Assuming you have a fixture for shopping lists
    @headers = { "X-SECURE-APP-USER-HASH" => "#{@user.app_hash}", "Content-Type" => "application/json" }
  end

  test "should create user with valid app_hash" do
    post login_or_create_api_v1_users_path,
         params: { user: { app_hash: "new_app_hash_123" } }.to_json,
         headers: { "Content-Type" => "application/json" }  # No auth header for create action
    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data["user_app_hash"] == "new_app_hash_123"
  end

  test "should login user with valid app_hash" do
    post login_or_create_api_v1_users_path,
         params: { user: { app_hash: "45ghg5g4g5g4g5g4g5g4g5g4g5g4g5g" } }.to_json,
         headers: { "Content-Type" => "application/json" }  # No auth header for create action
    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data["user_app_hash"] == "45ghg5g4g5g4g5g4g5g4g5g4g5g4g5g"
  end

  test "should login user quickly" do
    # We need to emasure the time in this request
    # If it takes too long, something is wrong
    start_time = Time.now
    post login_or_create_api_v1_users_path,
         params: { user: { app_hash: "45ghg5g4g5g4g5g4g5g4g5g4g5g4g5g" } }.to_json,
         headers: { "Content-Type" => "application/json" }  # No auth header for create action
    assert_response :success
    end_time = Time.now
    duration = end_time - start_time
    assert duration < 1, "Request took too long: #{duration} seconds"
    response_data = JSON.parse(response.body)
    assert response_data["user_app_hash"] == "45ghg5g4g5g4g5g4g5g4g5g4g5g4g5g"
  end

  test "should not create user with missing app_hash" do
    post login_or_create_api_v1_users_path,
         params: { user: { app_hash: "" } }.to_json,
         headers: { "Content-Type" => "application/json" }  # No auth header for create action
    assert_response :bad_request
    response_data = JSON.parse(response.body)
    assert_equal "app_hash is required", response_data["error"]
  end

  test "should update group_shopping_lists_items_by with valid value" do
    patch update_group_shopping_lists_items_by_api_v1_users_path,
          params: { group_shopping_lists_items_by: "place" }.to_json,
          headers: @headers

    assert_response :ok
    response_data = JSON.parse(response.body)
    assert_equal "Group shopping lists items by updated successfully", response_data["message"]
    assert_equal "place", response_data["user"]["group_shopping_lists_items_by"]
    @user.reload
    assert_equal "place", @user.group_shopping_lists_items_by
  end

  test "should not update group_shopping_lists_items_by with invalid value" do
    patch update_group_shopping_lists_items_by_api_v1_users_path,
          params: { group_shopping_lists_items_by: "invalid_value" }.to_json,
          headers: @headers

    assert_response :unprocessable_content
    response_data = JSON.parse(response.body)
    assert_includes response_data["errors"], "Group shopping lists items by is not included in the list"
    @user.reload
    assert_nil @user.group_shopping_lists_items_by # Ensure it remains unchanged
  end

  test "should not update group_shopping_lists_items_by if headers misses X-SECURE-APP-USER-HASH" do
    patch update_group_shopping_lists_items_by_api_v1_users_path,
          params: { group_shopping_lists_items_by: "asc" }.to_json,
          headers: { "Content-Type" => "application/json" }

    assert_response :bad_request
    response_data = JSON.parse(response.body)
    assert_equal "Invalid APP-USER-HASH", response_data["error"]
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
    assert_equal "Shopping list not found or user does not have access", response_data["error"]
    @user.reload
    assert_nil @user.active_shopping_list_id
  end

  test "should not update active shopping list with shopping list not belonging to user" do
    other_shopping_list = shopping_lists(:shopping_list_xyz) # Assuming this is a different list
    patch update_active_shopping_list_api_v1_users_path,
          params: { active_shopping_list_slug: other_shopping_list.slug }.to_json,
          headers: @headers

    assert_response :not_found
    response_data = JSON.parse(response.body)
    assert_equal "Shopping list not found or user does not have access", response_data["error"]
    @user.reload
    assert_nil @user.active_shopping_list_id
  end

  test "should not update active shopping list if headers misses X-SECURE-APP-USER-HASH" do
    patch update_active_shopping_list_api_v1_users_path,
          params: { active_shopping_list_slug: @shopping_list.slug }.to_json,
          headers: { "Content-Type" => "application/json" }

    assert_response :bad_request
    response_data = JSON.parse(response.body)
    assert_equal "Invalid APP-USER-HASH", response_data["error"]
    @user.reload
    assert_nil @user.active_shopping_list_id
  end

  test "should add shopping list to user with valid slug" do
    new_shopping_list = shopping_lists(:shopping_list_xyz) # Assuming this is a different list
    assert_difference("@user.shopping_lists.count", 1) do
      post add_shopping_list_api_v1_users_path,
           params: { shopping_list_slug: new_shopping_list.slug }.to_json,
           headers: @headers

      assert_response :ok
    end

    response_data = JSON.parse(response.body)
    assert_equal "Shopping list added to user successfully", response_data["message"]
    assert_includes @user.reload.shopping_lists, @shopping_list
  end

  test "should not add shopping list to user if already added" do
    assert_no_difference("@user.shopping_lists.count") do
      post add_shopping_list_api_v1_users_path,
           params: { shopping_list_slug: @shopping_list.slug }.to_json,
           headers: @headers

      assert_response :ok
    end

    response_data = JSON.parse(response.body)
    assert_equal "Shopping list belonged to user already", response_data["message"]
    assert_includes @user.reload.shopping_lists, @shopping_list
  end

  test "should not add shopping list with invalid slug" do
    assert_no_difference("@user.shopping_lists.count") do
      post add_shopping_list_api_v1_users_path,
           params: { shopping_list_slug: "invalid_slug" }.to_json,
           headers: @headers

      assert_response :not_found
    end

    response_data = JSON.parse(response.body)
    assert_equal "Shopping list not found", response_data["error"]
  end

  test "should not add shopping list if headers misses X-SECURE-APP-USER-HASH" do
    assert_no_difference("@user.shopping_lists.count") do
      post add_shopping_list_api_v1_users_path,
           params: { shopping_list_slug: @shopping_list.slug }.to_json,
           headers: { "Content-Type" => "application/json" }

      assert_response :bad_request
    end

    response_data = JSON.parse(response.body)
    assert_equal "Invalid APP-USER-HASH", response_data["error"]
  end

  test "should not add shopping list if user not found" do
    assert_no_difference("@user.shopping_lists.count") do
      post add_shopping_list_api_v1_users_path,
           params: { shopping_list_slug: @shopping_list.slug }.to_json,
           headers: { "X-SECURE-APP-USER-HASH" => "wrong_hash", "Content-Type" => "application/json" }

      assert_response :unauthorized
    end

    response_data = JSON.parse(response.body)
    assert_equal "Unauthorized", response_data["error"]
  end

  test "should remove shopping list from user with valid slug" do
    @user.shopping_lists << @shopping_list unless @user.shopping_lists.include?(@shopping_list)
    assert_difference("@user.shopping_lists.count", -1) do
      post remove_shopping_list_api_v1_users_path,
           params: { shopping_list_slug: @shopping_list.slug }.to_json,
           headers: @headers

      assert_response :ok
    end

    response_data = JSON.parse(response.body)
    assert_equal "Shopping list removed from user successfully", response_data["message"]
    refute_includes @user.reload.shopping_lists, @shopping_list
  end

  test "should not remove shopping list from user that does not have it" do
    not_owned_shopping_list = shopping_lists(:shopping_list_xyz) # Assuming this is a different list
    assert_no_difference("@user.shopping_lists.count") do
      post remove_shopping_list_api_v1_users_path,
           params: { shopping_list_slug: not_owned_shopping_list.slug }.to_json,
           headers: @headers

      assert_response :unauthorized
    end

    response_data = JSON.parse(response.body)
    assert_equal "User does not have access to this shopping list", response_data["error"]
  end

  test "should not remove shopping list with invalid slug" do
    assert_no_difference("@user.shopping_lists.count") do
      post remove_shopping_list_api_v1_users_path,
           params: { shopping_list_slug: "invalid_slug" }.to_json,
           headers: @headers

      assert_response :not_found
    end

    response_data = JSON.parse(response.body)
    assert_equal "Shopping list not found", response_data["error"]
  end

  test "should get all shopping list slugs for user" do
    get fetch_all_shopping_lists_slugs_api_v1_users_path,
        headers: @headers

    assert_response :ok
    response_data = JSON.parse(response.body)
    assert_includes response_data["shopping_lists"], @shopping_list.slug
    assert_equal @user.shopping_lists.count, response_data["shopping_lists"].size
    assert_equal @user.shopping_lists.pluck(:slug).sort, response_data["shopping_lists"].sort
    assert_not response_data["shopping_lists"].empty?
    assert_equal response_data["shopping_lists"].size, 2
  end
end
