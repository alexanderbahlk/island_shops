module Api
  module V1
    class ShoppingListsController < ApplicationController
      protect_from_forgery with: :null_session

      SECURE_HASH = ENV.fetch("CATEGORIES_API_HASH", "gfh5haf_y6").freeze

      before_action :find_shopping_list, only: [:show, :update, :destroy]

      # GET /api/v1/shopping_lists/:slug
      def show
        return head :unauthorized unless params[:hash] == SECURE_HASH
        render json: {
          slug: @shopping_list.slug,
          display_name: @shopping_list.display_name,
          shopping_list_items: @shopping_list.shopping_list_items.as_json(only: [:uuid, :title, :purchased]).sort_by { |item| item[:title] },
        }
      end

      # POST /api/v1/shopping_lists
      def create
        Rails.logger.info("Received params: #{params.inspect}")
        return head :unauthorized unless params[:hash] == SECURE_HASH

        shopping_list = ShoppingList.new(display_name: params[:display_name], shopping_list_items: [])

        if shopping_list.save
          render json: { slug: shopping_list.slug, display_name: shopping_list.display_name }, status: :created
        else
          render json: { errors: shopping_list.errors.full_messages }, status: :unprocessable_content
        end
      end

      # PATCH /api/v1/shopping_lists/:slug
      def update
        Rails.logger.info("Received params: #{params.inspect}")
        return head :unauthorized unless params[:hash] == SECURE_HASH
        if @shopping_list.update(shopping_list_params)
          render json: {
            slug: @shopping_list.slug,
            display_name: @shopping_list.display_name,
            shopping_list_items: @shopping_list.shopping_list_items.as_json(only: [:uuid, :title, :purchased]).sort_by { |item| item[:title] },
          }
        else
          render json: { errors: @shopping_list.errors.full_messages }, status: :unprocessable_content
        end
      end

      def destroy
        Rails.logger.info("Received params: #{params.inspect}")
        return head :unauthorized unless params[:hash] == SECURE_HASH

        if @shopping_list.destroy
          slug = @shopping_list.slug
          render json: {
            slug: slug,
          }, status: :ok
        else
          render json: { errors: @shopping_list.errors.full_messages }, status: :unprocessable_content
        end
      end

      private

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
