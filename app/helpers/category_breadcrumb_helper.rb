module CategoryBreadcrumbHelper
  def build_breadcrumb_by_uuid(category_uuid)
    category = Category.find_by(uuid: category_uuid)
    Rails.logger.info "Looking for category with UUID: #{category_uuid}"
    return [] unless category
    Rails.logger.info "Found category: #{category.title}"
    build_breadcrumb(category)
  end

  def build_breadcrumb(category)
    breadcrumb_parts = []
    current_category = category
    while current_category
      breadcrumb_parts.unshift(current_category.title)
      current_category = current_category.parent
    end
    breadcrumb_parts.pop
    breadcrumb_parts
  rescue
    [category.title]
  end
end
