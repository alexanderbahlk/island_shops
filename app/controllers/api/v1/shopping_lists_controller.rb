module Api
  module V1
    class ShoppingListsController < Api::V1::SecureAppController
      before_action :find_shopping_list, only: [:show, :update, :destroy, :delete_all_purchased_shopping_list_items]

      # GET /api/v1/shopping_lists/:slug
      def show
        render json: shopping_list_json
      end

      # POST /api/v1/shopping_lists
      def create
        Rails.logger.info("Received params: #{params.inspect}")

        shopping_list = ShoppingList.new(display_name: params[:display_name], shopping_list_items: [])
        shopping_list.users << current_user
        if shopping_list.save
          render json: { slug: shopping_list.slug, group_shopping_lists_items_by: current_user.group_shopping_lists_items_by, display_name: shopping_list.display_name }, status: :created
        else
          render json: { errors: shopping_list.errors.full_messages }, status: :unprocessable_content
        end
      end

      # PATCH /api/v1/shopping_lists/:slug
      def update
        Rails.logger.info("Received params: #{params.inspect}")
        if @shopping_list.update(shopping_list_params)
          render json: shopping_list_json
        else
          render json: { errors: @shopping_list.errors.full_messages }, status: :unprocessable_content
        end
      end

      def destroy
        Rails.logger.info("Received params for destroy: #{params.inspect}")
        Rails.logger.info("Attempting to destroy ShoppingList with slug: #{@shopping_list.slug}")
        to_destroy_slug = @shopping_list.slug
        if @shopping_list.destroy
          # If the users active shopping list is the one being deleted, assign a new one or nil
          new_active = @current_user.shopping_lists.where.not(slug: to_destroy_slug).first
          @current_user.update(active_shopping_list: new_active)
          render json: {
            slug: to_destroy_slug,
          }, status: :ok
        else
          render json: { errors: @shopping_list.errors.full_messages }, status: :unprocessable_content
        end
      end

      def delete_all_purchased_shopping_list_items
        Rails.logger.info("Received request to delete all purchased items for ShoppingList with slug: #{@shopping_list.slug}")

        purchased_items = @shopping_list.shopping_list_items.purchased
        if purchased_items.destroy_all
          render json: { message: "All purchased items have been deleted." }, status: :ok
        else
          render json: { errors: "Failed to delete purchased items." }, status: :unprocessable_entity
        end
      end

      private

      def shopping_list_json
        {
          slug: @shopping_list.slug,
          group_shopping_lists_items_by: current_user.group_shopping_lists_items_by,
          display_name: @shopping_list.display_name,
          shopping_list_items: @shopping_list.shopping_list_items_for_view_list(@current_user.group_shopping_lists_items_by),
          shopping_list_items_count: @shopping_list.shopping_list_items.count,
          shopping_list_items_purchased_count: @shopping_list.shopping_list_items.purchased.count,
        }
      end

      def find_shopping_list
        @shopping_list = ShoppingList.find_by!(slug: params[:slug])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "ShoppingList not found" }, status: :not_found
      end

      def shopping_list_params
        params.require(:shopping_list).permit(:display_name,
                                              shopping_list_item_uuids: [] # Allow updating associated categories
          )
      end
    end
  end
end
