ActiveAdmin.register_page 'Priority Shop Items' do
  menu parent: 'Shop Items', label: 'Priority Shop Items'

  content title: 'Priority Shop Items' do
    panel 'Products with high Shop Item Count' do
      products = Category.products
      priority_shop_items = []
      products.each do |product|
        pending_approval_count = product.shop_items.pending_approval.count
        next unless pending_approval_count > 1

        approved_count = product.shop_items.approved.count
        all_count = product.shop_items.all.count
        to_approve_ratio = if all_count.positive?
                             pending_approval_count.to_f / all_count.to_f
                           else
                             0
                           end
        priority_shop_items << { product: product, pending_approval_count: pending_approval_count,
                                 approved_count: approved_count, all_count: all_count, to_approve_ratio: to_approve_ratio }
      end
      priority_shop_items.sort_by! { |item| -item[:to_approve_ratio] }
      ul class: 'priority-shop_item-list' do
        priority_shop_items.each do |item|
          li class: 'priority-shop_item-list-item' do
            span "(Id: #{item[:product].id}) #{item[:product].title} - #{item[:pending_approval_count]} from #{item[:all_count]} shop items pending approval (#{(item[:to_approve_ratio] * 100).round(2)}% to approve)"
            text_node link_to 'View Shop Items',
                              admin_shop_items_path(q: { category_id_eq: item[:product].id, status_eq: 'pending_approval' }), style: 'margin-left: 10px;'
            text_node ' | '
            text_node link_to 'Start Overwrite Job',
                              admin_priority_shop_items_start_overwrite_job_path(old_category_id: item[:product].id), method: :post, data: { confirm: 'Are you sure you want to start the AssignShopItemCategoryJob for this product?' }, style: 'margin-left: 10px;'
          end
        end
      end
    end
  end

  # Add a custom action to start the OverwriteShopItemCategoryJob
  page_action :start_overwrite_job, method: :post do
    old_category_id = params[:old_category_id]

    if old_category_id.present?
      AssignShopItemCategoryJob.perform_later(category_id: old_category_id)
      flash[:notice] = "AssignShopItemCategoryJob has been started for category ID #{old_category_id}."
    else
      flash[:error] = 'Invalid parameters. Job could not be started.'
    end

    redirect_to admin_priority_shop_items_path
  end
end
