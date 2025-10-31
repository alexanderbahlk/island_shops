ActiveAdmin.register_page "Priority Shop Items" do
  menu parent: "Shop Items", label: "Priority Shop Items"

  content title: "Priority Shop Items" do
    panel "Products with high Shop Item Count" do
      products = Category.products
      priority_shop_items = []
      products.each do |product|
        count = product.shop_items.pending_approval.count
        if count > 1
          priority_shop_items << { product: product, count: count }
        end
      end
      priority_shop_items.sort_by! { |item| -item[:count] }
      ul class: "priority-shop_item-list" do
        priority_shop_items.each do |item|
          li class: "priority-shop_item-list-item" do
            span "#{item[:product].title} - #{item[:count]}"
            text_node link_to "View Shop Items", admin_shop_items_path(q: { category_id_eq: item[:product].id, status_eq: "pending_approval" }), style: "margin-left: 10px;"
            text_node " | "
            text_node link_to "Start Overwrite Job", admin_priority_shop_items_start_overwrite_job_path(old_category_id: item[:product].id), method: :post, data: { confirm: "Are you sure you want to start the OverwriteShopItemCategoryJob for this product?" }, style: "margin-left: 10px;"
          end
        end
      end
    end
  end

  # Add a custom action to start the OverwriteShopItemCategoryJob
  page_action :start_overwrite_job, method: :post do
    old_category_id = params[:old_category_id]
    similarity_threshold = 0.35 # You can adjust the threshold as needed

    if old_category_id.present? && similarity_threshold.present?
      OverwriteShopItemCategoryJob.perform_later(old_category_id: old_category_id, similarity_threshold: similarity_threshold)
      flash[:notice] = "OverwriteShopItemCategoryJob has been started for category ID #{old_category_id}."
    else
      flash[:error] = "Invalid parameters. Job could not be started."
    end

    redirect_to admin_priority_shop_items_path
  end
end
