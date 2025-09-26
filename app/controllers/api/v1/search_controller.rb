class Api::V1::SearchController < Api::V1::SecureAppController
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
    service = ProductSearch.new(
      query: params[:q],
      limit: 10,
    )
    render json: service.results
  end
end
