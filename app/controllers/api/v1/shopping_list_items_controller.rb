module Api
  module V1
    class ShoppingListItemsController < Api::V1::SecureAppController
      include CategoryBreadcrumbHelper

      before_action :find_shopping_list, only: [:create]
      before_action :find_shopping_list_item_by_uuid, only: %i[destroy update]

      # POST /api/v1/shopping_lists/:shopping_list_slug/shopping_list_items
      def create
        Rails.logger.info("Received params: #{params.inspect}")

        # Resolve category_uuid to a Category record
        if shopping_list_item_params[:category_uuid]
          category = Category.find_by(uuid: shopping_list_item_params[:category_uuid])
        end

        # Build the ShoppingListItem
        shopping_list_item = @shopping_list.shopping_list_items.build(
          title: shopping_list_item_params[:title],
          category: category || nil,
          user: current_user
        )

        if shopping_list_item.save
          ActionCable.server.broadcast("notifications_#{@shopping_list.slug}", {
                                         type: 'shopping_list_item_created',
                                         current_user_app_hash: current_user&.app_hash
                                       })
          render json: shopping_list_item_json_response(shopping_list_item), status: :created
        else
          render json: { errors: shopping_list_item.errors.full_messages }, status: :unprocessable_content
        end
      end

      # DELETE /api/v1/shopping_list_items/:uuid
      def destroy
        Rails.logger.info("Received params: #{params.inspect}")
        shopping_list_slug = @shopping_list_item.shopping_list.slug
        if @shopping_list_item.destroy
          ActionCable.server.broadcast("notifications_#{shopping_list_slug}", {
                                         type: 'shopping_list_deleted',
                                         current_user_app_hash: current_user&.app_hash
                                       })
          render json: { message: 'ShoppingListItem deleted successfully' }, status: :ok
        else
          render json: { errors: @shopping_list_item.errors.full_messages }, status: :unprocessable_content
        end
      end

      def update
        Rails.logger.info("Received params update: #{params.inspect}")

        update_params = shopping_list_item_params

        if params[:shop_item] && params[:shop_item].key?(:uuid)
          Rails.logger.info("Looking up ShopItem with UUID: #{params[:shop_item][:uuid].inspect}")
          shop_item = ShopItem.find_by(uuid: params[:shop_item][:uuid])

          if shop_item
            update_params.merge!(shop_item_id: shop_item.id)
          else
            # If the UUID is nil or invalid, explicitly set shop_item_id to nil
            update_params.merge!(shop_item_id: nil)
          end
        end

        if @shopping_list_item.update(update_params)
          ActionCable.server.broadcast("notifications_#{@shopping_list_item.shopping_list.slug}", {
                                         type: 'shopping_list_item_updated',
                                         current_user_app_hash: current_user&.app_hash
                                       })
          render json: shopping_list_item_json_response(@shopping_list_item), status: :ok
        else
          render json: { errors: @shopping_list_item.errors.full_messages }, status: :unprocessable_content
        end
      end

      private

      def shopping_list_item_json_response(shopping_list_item)
        {
          uuid: shopping_list_item.uuid,
          title: shopping_list_item.title_for_shopping_list_grouping(current_user.group_shopping_lists_items_by),
          purchased: shopping_list_item.purchased,
          quantity: shopping_list_item.quantity,
          breadcrumb: shopping_list_item.category.present? ? build_breadcrumb(shopping_list_item.category) : []
        }
      end

      def find_shopping_list
        @shopping_list = ShoppingList.find_by!(slug: params[:shopping_list_slug])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'ShoppingList not found' }, status: :not_found
      end

      def find_shopping_list_item_by_uuid
        @shopping_list_item = ShoppingListItem.find_by!(uuid: params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'ShoppingListItem not found' }, status: :not_found
      end

      def shopping_list_item_params
        params.require(:shopping_list_item).permit(:title, :category_uuid, :purchased, :quantity, :priority)
      end
    end
  end
end
