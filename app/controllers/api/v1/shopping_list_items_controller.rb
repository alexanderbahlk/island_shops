module Api
  module V1
    class ShoppingListItemsController < Api::V1::SecureAppController
      include CategoryBreadcrumbHelper

      before_action :find_shopping_list, only: [:create]
      before_action :find_shopping_list_item_by_uuid, only: [:destroy, :update]

      # POST /api/v1/shopping_lists/:shopping_list_slug/shopping_list_items
      def create
        Rails.logger.info("Received params: #{params.inspect}")

        if !current_user
          render json: { error: "Unauthorized - User not found" }, status: :unauthorized
          return
        end

        # Resolve category_uuid to a Category record
        category = Category.find_by(uuid: shopping_list_item_params[:category_uuid])

        # Build the ShoppingListItem
        item = @shopping_list.shopping_list_items.build(
          title: shopping_list_item_params[:title],
          category: category,
          user: current_user,
        )

        if item.save
          ActionCable.server.broadcast("notifications_#{@shopping_list.slug}", {
            type: "shopping_list_item_created",
            current_user_app_hash: current_user&.app_hash,
            item: {
              uuid: item.uuid,
              title: item.title,
              purchased: item.purchased,
              quantity: item.quantity,
              breadcrumb: item.category.present? ? build_breadcrumb(item.category) : [],
            },
          })
          render json: {
            uuid: item.uuid,
            title: item.title,
            purchased: item.purchased,
            quantity: item.quantity,
            breadcrumb: item.category.present? ? build_breadcrumb(item.category) : [],
          }, status: :created
        else
          render json: { errors: item.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/shopping_list_items/:uuid
      def destroy
        Rails.logger.info("Received params: #{params.inspect}")
        shopping_list_slug = @shopping_list_item.shopping_list.slug
        shopping_list_item_uuid = @shopping_list_item.uuid
        if @shopping_list_item.destroy
          ActionCable.server.broadcast("notifications_#{shopping_list_slug}", {
            type: "shopping_list_deleted",
            item: {
              uuid: shopping_list_item_uuid,
            },
            current_user_app_hash: current_user&.app_hash,
          })
          render json: { message: "ShoppingListItem deleted successfully" }, status: :ok
        else
          render json: { errors: @shopping_list_item.errors.full_messages }, status: :unprocessable_content
        end
      end

      def update
        Rails.logger.info("Received params update: #{params.inspect}")
        if @shopping_list_item.update(shopping_list_item_params)
          ActionCable.server.broadcast("notifications_#{@shopping_list_item.shopping_list.slug}", {
            type: "shopping_list_item_updated",
            current_user_app_hash: current_user&.app_hash,
            item: {
              uuid: @shopping_list_item.uuid,
              title: @shopping_list_item.title,
              purchased: @shopping_list_item.purchased,
              quantity: @shopping_list_item.quantity,
              breadcrumb: @shopping_list_item.category.present? ? build_breadcrumb(@shopping_list_item.category) : [],
            },
          })
          render json: {
            uuid: @shopping_list_item.uuid,
            title: @shopping_list_item.title,
            purchased: @shopping_list_item.purchased,
            quantity: @shopping_list_item.quantity,
            breadcrumb: @shopping_list_item.category.present? ? build_breadcrumb(@shopping_list_item.category) : [],
          }, status: :ok
        else
          render json: { errors: @shopping_list_item.errors.full_messages }, status: :unprocessable_entity
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
        params.require(:shopping_list_item).permit(:title, :category_uuid, :purchased, :quantity, :priority)
      end
    end
  end
end
