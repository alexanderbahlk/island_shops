module Api
  module V1
    class ShoppingListItemsController < ApplicationController
      protect_from_forgery with: :null_session

      SECURE_HASH = ENV.fetch("CATEGORIES_API_HASH", "gfh5haf_y6").freeze

      before_action :find_shopping_list, only: [:create]
      before_action :find_shopping_list_item_by_uuid, only: [:destroy]

      # POST /api/v1/shopping_lists/:shopping_list_slug/shopping_list_items
      def create
        Rails.logger.info("Received params: #{params.inspect}")
        return head :unauthorized unless params[:hash] == SECURE_HASH

        # Resolve category_uuid to a Category record
        category = Category.find_by(uuid: shopping_list_item_params[:category_uuid])

        # Build the ShoppingListItem
        item = @shopping_list.shopping_list_items.build(
          title: shopping_list_item_params[:title],
          category: category,
        )

        if item.save
          render json: {
            uuid: item.uuid,
            title: item.title,
            category_uuid: item.category&.uuid,
          }, status: :created
        else
          render json: { errors: item.errors.full_messages }, status: :unprocessable_content
        end
      end

      # DELETE /api/v1/shopping_list_items/:uuid
      def destroy
        Rails.logger.info("Received params: #{params.inspect}")
        return head :unauthorized unless params[:hash] == SECURE_HASH
        if @shopping_list_item.destroy
          render json: { message: "ShoppingListItem deleted successfully" }, status: :ok
        else
          render json: { errors: @shopping_list_item.errors.full_messages }, status: :unprocessable_content
        end
      end

      private

      def find_shopping_list
        @shopping_list = ShoppingList.find_by!(slug: params[:shopping_list_slug])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "ShoppingList not found" }, status: :not_found
      end

      def find_shopping_list_item_by_uuid
        @shopping_list_item = ShoppingListItem.find_by!(uuid: params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "ShoppingListItem not found" }, status: :not_found
      end

      def shopping_list_item_params
        params.require(:shopping_list_item).permit(:title, :category_uuid)
      end
    end
  end
end
