class Api::V1::UsersController < Api::V1::SecureAppController

  #ignore authenticate method if create endpoint
  skip_before_action :authenticate, only: [:login_or_create]

  def login_or_create
    user_params = params.require(:user).permit(:app_hash)
    render json: { error: "app_hash is required" }, status: :bad_request and return if user_params[:app_hash].blank?
    @current_user = User.find_by(app_hash: user_params[:app_hash])
    if @current_user.nil?
      @current_user = User.new(app_hash: user_params[:app_hash])
      if @current_user.save
        render json: { user_app_hash: @current_user.app_hash }, status: :ok
      else
        render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_content
      end
    else
      render json: { user_app_hash: @current_user.app_hash }, status: :ok
    end
  end

  ## returns only the shopping list that belong to the user
  ## return the slugs and a boolen if it is the active shopping list
  def fetch_all_shopping_lists_slugs
    shopping_list_slugs = @current_user.shopping_lists.pluck(:slug)
    active_shopping_list_slug = @current_user.active_shopping_list&.slug
    Rails.logger.info("User #{@current_user.id} has shopping lists: #{shopping_list_slugs}, active: #{active_shopping_list_slug}")
    render json: { shopping_lists: shopping_list_slugs, active_shopping_list: active_shopping_list_slug }, status: :ok
  end

  def update_group_shopping_lists_items_by
    if @current_user.update(group_shopping_lists_items_by: params[:group_shopping_lists_items_by])
      render json: { message: "Group shopping lists items by updated successfully", user: @current_user }, status: :ok
    else
      render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update_active_shopping_list
    shopping_list = ShoppingList.find_by(slug: params[:active_shopping_list_slug])

    if shopping_list.nil? || !@current_user.shopping_lists.include?(shopping_list)
      render json: { error: "Shopping list not found or user does not have access" }, status: :not_found
      return
    end

    if @current_user.update(active_shopping_list: shopping_list)
      render json: { message: "Active shopping list updated successfully", user: @current_user }, status: :ok
    else
      render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_content
    end
  end

  def add_shopping_list
    shopping_list = ShoppingList.find_by(slug: params[:shopping_list_slug])

    if shopping_list.nil?
      render json: { error: "Shopping list not found" }, status: :not_found
      return
    end

    unless @current_user.shopping_lists.include?(shopping_list)
      @current_user.shopping_lists << shopping_list
      if @current_user.save
        render json: { message: "Shopping list added to user successfully", user: @current_user }, status: :ok
      else
        render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_content
      end
    else
      render json: { message: "Shopping list belonged to user already", user: @current_user }, status: :ok
      return
    end
  end

  def remove_shopping_list
    shopping_list = ShoppingList.find_by(slug: params[:shopping_list_slug])

    if shopping_list.nil?
      render json: { error: "Shopping list not found" }, status: :not_found
      return
    end

    if !@current_user.shopping_lists.include?(shopping_list)
      render json: { error: "User does not have access to this shopping list" }, status: :unauthorized
      return
    end

    to_destroy_slug = shopping_list.slug
    new_active = @current_user.shopping_lists.where.not(slug: to_destroy_slug).first
    @current_user.update(active_shopping_list: new_active)

    @current_user.shopping_lists.delete(shopping_list)
    if @current_user.save
      render json: { message: "Shopping list removed from user successfully", user: @current_user }, status: :ok
    else
      render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_content
    end
  end
end
