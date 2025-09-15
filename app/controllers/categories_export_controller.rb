class CategoriesExportController < ApplicationController
  # Replace with your own secure hash!
  SECURE_HASH = ENV.fetch("CATEGORIES_EXPORT_HASH") { "hello" }

  def index
    unless params[:hash] == SECURE_HASH
      render plain: "Unauthorized", status: :unauthorized and return
    end

    @categories = Category.where(parent_id: nil).includes(children: :children)
    respond_to do |format|
      format.xml
    end
  end
end
