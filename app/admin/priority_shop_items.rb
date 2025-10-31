ActiveAdmin.register_page "Priority Shop Items" do
  menu parent: "Shop Items", label: "Priority Shop Items"

  content title: "Priority Shop Items" do
    panel "Products with high Shop Item Count" do
      products = Category.products
      priority_shop_items = []
      products.each do |product|
        count = product.shop_items.pending_approval.count
        if count > 5
          priority_shop_items << { product: product, count: count }
        end
      end
      priority_shop_items.sort_by! { |item| -item[:count] }
      ul class: "priority-shop_item-list" do
        priority_shop_items.each do |item|
          li class: "priority-shop_item-list-item" do
            span "#{item[:product].title} - #{item[:count]}"
            text_node link_to "View Shop Items", admin_shop_items_path(q: { category_id_eq: item[:product].id, status_eq: "pending_approval" }), style: "margin-left: 10px;"
          end
        end
      end
    end
  end
end
