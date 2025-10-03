class Api::V1::UsersController < Api::V1::SecureAppController
  def update_group_shopping_lists_items_by
    if @current_user.update(group_shopping_lists_items_by: params[:group_shopping_lists_items_by])
      render json: { message: "Group shopping lists items by updated successfully", user: @current_user }, status: :ok
    else
      render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update_active_shopping_list
    shopping_list = ShoppingList.find_by(slug: params[:active_shopping_list_slug])

    if shopping_list.nil?
      render json: { error: "Shopping list not found" }, status: :not_found
      return
    end

    if @current_user.update(active_shopping_list: shopping_list)
      render json: { message: "Active shopping list updated successfully", user: @current_user }, status: :ok
    else
      render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_content
    end
  end
end
