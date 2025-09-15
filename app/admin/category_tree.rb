ActiveAdmin.register_page "Category Tree" do
  menu parent: "Categories", label: "Category Tree"

  content title: "Category Tree" do
    panel "All Categories (Tree View)" do
      roots = Category.where(parent_id: nil).includes(:children)

      def render_category_tree(categories)
        ul do
          categories.each do |category|
            li do
              span best_in_place(category, :title, as: :input, url: [:admin, category]), class: "editable-title"
              text_node " (#{category.category_type})"
              text_node " - "
              # Link to edit the category
              text_node link_to("View", admin_category_path(category), class: "edit-link")
              # Recursively render children
              if category.children.any?
                render_category_tree(category.children)
              end
            end
          end
        end
      end

      render_category_tree(roots)
    end
  end

  # Ensure best_in_place is initialized
  page_action :bip, method: :put do
    category = Category.find(params[:id])
    category.update(title: params[:category][:title])
    render json: { title: category.title }
  end

  # Optionally, add JS to initialize best_in_place on page load
  # (in app/assets/javascripts/active_admin.js)
  # $(document).on('turbolinks:load', function(){
  #   $(".best_in_place").best_in_place();
  # });
end
