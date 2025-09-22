module Api
  module V1
    class ShoppingListsController < ApplicationController
      before_action :find_shopping_list, only: [:show, :update]

      # GET /api/v1/shopping_lists/:slug
      def show
        render json: {
          slug: @shopping_list.slug,
          categories: @shopping_list.categories.as_json(only: [:uuid, :title]),
          products_temp: @shopping_list.products_temp,
        }
      end

      # POST /api/v1/shopping_lists
      def create
        shopping_list = ShoppingList.new(shopping_list_params)

        if shopping_list.save
          render json: { slug: shopping_list.slug }, status: :created
        else
          render json: { errors: shopping_list.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/shopping_lists/:slug
      def update
        if @shopping_list.update(shopping_list_params)
          render json: {
            slug: @shopping_list.slug,
            categories: @shopping_list.categories.as_json(only: [:uuid, :title]),
            products_temp: @shopping_list.products_temp,
          }
        else
          render json: { errors: @shopping_list.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def find_shopping_list
        @shopping_list = ShoppingList.find_by!(slug: params[:slug])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "ShoppingList not found" }, status: :not_found
      end

      def shopping_list_params
        params.require(:shopping_list).permit(
          products_temp: [],
          category_uuids: [], # Allow updating associated categories
        )
      end
    end
  end
end
