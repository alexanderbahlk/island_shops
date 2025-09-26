module Api
  module V1
    class CategoriesController < Api::V1::SecureAppController
      def shop_items
        Rails.logger.info("Received params: #{params.inspect}")

        # Find the category by UUID
        category = Category.find_by(uuid: params[:category_uuid])
        if category.nil?
          render json: { error: "Category not found" }, status: :not_found
          return
        end

        # Fetch shop items using the service
        service = FetchShopItemsForCategoryService.new(
          category: category,
          hide_out_of_stock: params[:hide_out_of_stock] == "true",
          limit: params[:limit]&.to_i || 5,
        )
        shop_items = service.fetch_shop_items

        render json: shop_items, status: :ok
      rescue => e
        Rails.logger.error("Error fetching shop items: #{e.message}")
        render json: { error: "An error occurred while fetching shop items" }, status: :internal_server_error
      end
    end
  end
end
