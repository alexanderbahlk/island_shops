class Api::V1::UsersController < Api::V1::SecureAppController
  def update_sorting_order
    if @current_user.nil?
      render json: { error: "User not found" }, status: :not_found
      return
    end

    if @current_user.update(sorting_order: params[:sorting_order])
      render json: { message: "Sorting order updated successfully", user: @current_user }, status: :ok
    else
      render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_content
    end
  end
end
