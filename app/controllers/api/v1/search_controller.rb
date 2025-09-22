class Api::V1::SearchController < ApplicationController
  # Simple hash to secure the products endpoint
  SECURE_HASH = ENV.fetch("CATEGORIES_API_HASH", "gfh5haf_y6").freeze

  def index
    @initial_query = params[:q]&.strip
    render "search/index"
  end

  def products_with_shop_items
    service = CategoryShopItemSearch.new(
      query: params[:q],
      hide_out_of_stock: params[:out_of_stock] == "true",
      limit: 10,
    )
    render json: service.results
  end

  def products
    return head :unauthorized unless params[:hash] == SECURE_HASH
    service = ProductSearch.new(
      query: params[:q],
      hide_out_of_stock: params[:out_of_stock] == "true",
      limit: 10,
    )
    render json: service.results
  end
end
