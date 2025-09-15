class SearchController < ApplicationController
  def index
    @initial_query = params[:q]&.strip
  end

  def categories
    service = CategoryShopItemSearch.new(
      query: params[:q],
      hide_out_of_stock: params[:out_of_stock] == "true",
      limit: 5,
    )
    render json: service.results
  end
end
