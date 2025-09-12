# == Schema Information
#
# Table name: categories
#
#  id            :bigint           not null, primary key
#  category_type :integer          default("root"), not null
#  depth         :integer          default(0)
#  lft           :integer          not null
#  path          :string
#  rgt           :integer          not null
#  slug          :string           not null
#  sort_order    :integer          default(0)
#  title         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  parent_id     :bigint
#
# Indexes
#
#  index_categories_on_category_type             (category_type)
#  index_categories_on_lft_and_rgt               (lft,rgt)
#  index_categories_on_parent_id                 (parent_id)
#  index_categories_on_parent_id_and_slug        (parent_id,slug) UNIQUE
#  index_categories_on_parent_id_and_sort_order  (parent_id,sort_order)
#  index_categories_on_path                      (path)
#
# Foreign Keys
#
#  fk_rails_...  (parent_id => categories.id)
#
class Category < ApplicationRecord
  # Use acts_as_nested_set for efficient tree operations
  acts_as_nested_set order_column: :sort_order

  has_many :shop_items, dependent: :nullify
  belongs_to :parent, class_name: "Category", optional: true
  has_many :children, class_name: "Category", foreign_key: "parent_id", dependent: :destroy

  enum category_type: {
    root: 0,           # Food, Health & Beauty, etc.
    category: 1,        # Fresh Food, Dairy, etc.
    subcategory: 2,        # Vegetables, Fruits, etc.
    product: 3,       # Tomatoes, Parmesan, etc.
  }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: { scope: :parent_id }
  validates :category_type, presence: true
  validate :validate_hierarchy_depth

  before_validation :generate_slug, :set_category_type, :build_path
  after_save :update_children_paths, if: :saved_change_to_path?

  # Add this callback to handle shop item references before deletion
  around_destroy :clear_all_references_around_destroy

  scope :roots, -> { where(parent_id: nil) }
  scope :products, -> { where(category_type: :product) }
  scope :categories_only, -> { where.not(category_type: :product) }
  scope :with_shop_items, -> { joins(:shop_items).distinct }

  # Efficient queries using materialized path
  scope :under_path, ->(path) { where("path LIKE ?", "#{path}%") }
  scope :direct_children_of, ->(parent_path) {
          where("path LIKE ? AND depth = ?", "#{parent_path}/%", parent_path.split("/").length + 1)
        }

  def self.ransackable_attributes(auth_object = nil)
    ["category_type", "created_at", "depth", "id", "id_value", "lft", "parent_id", "path", "rgt", "slug", "sort_order", "title", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["children", "parent", "shop_items"]
  end

  def self.parent_options_for_select
    # Simple approach without using arrange
    where.not(category_type: :product)
      .includes(:parent)
      .order(:lft) # Use nested set ordering
      .map do |category|
      # Create indented display name based on depth
      indent = "--" * category.depth
      ["#{indent}#{category.title}", category.id]
    end
  end

  def self.only_products
    products.includes(:parent).map { |cat| [cat.breadcrumbs.map(&:full_path).join(" > "), cat.id] }
  end

  def full_path
    path || build_path_string
  end

  def ancestors_titles
    path ? path.split("/") : []
  end

  def breadcrumbs
    return [self] if root?

    # Get ancestors in correct order (root first)
    ancestors.reorder(:lft) + [self]
  end

  def can_have_children?
    !product?
  end

  def can_have_items?
    product?
  end

  # Get all item types under this category
  def all_products
    return Category.none unless can_have_children?

    descendants.products
  end

  # Find similar categories using trigram matching
  def self.find_similar(title, threshold: 0.3, limit: 5)
    return none if title.blank?

    select("*, similarity(title, ?) as sim_score")
      .where("similarity(title, ?) > ?", title, threshold)
      .order("sim_score DESC")
      .limit(limit)
  end

  # Remove the callback and add this method instead:
  def destroy
    # Use a transaction to ensure atomicity
    ActiveRecord::Base.transaction do
      # Get all descendant IDs before any deletion
      descendant_ids = self_and_descendants.pluck(:id)

      # Clear all shop item references first
      cleared_count = ShopItem.where(category_id: descendant_ids).update_all(category_id: nil, approved: false)
      Rails.logger.info "Cleared #{cleared_count} shop item references for category '#{title}' and its descendants before deletion"

      # Now call the parent destroy method
      super
    end
  end

  def destroy!
    # Use a transaction to ensure atomicity
    ActiveRecord::Base.transaction do
      # Get all descendant IDs before any deletion
      descendant_ids = self_and_descendants.pluck(:id)

      # Clear all shop item references first
      cleared_count = ShopItem.where(category_id: descendant_ids).update_all(category_id: nil, approved: false)
      Rails.logger.info "Cleared #{cleared_count} shop item references for category '#{title}' and its descendants before deletion"

      # Now call the parent destroy! method
      super
    end
  end

  private

  # Remove the old clear_shop_item_references method and replace with this:
  def clear_all_references_around_destroy
    # Get all descendant IDs before destruction begins
    descendant_ids = self_and_descendants.pluck(:id)

    # Clear all shop item references for this category and all descendants
    cleared_count = ShopItem.where(category_id: descendant_ids).update_all(category_id: nil, approved: false)
    Rails.logger.info "Cleared #{cleared_count} shop item references for category '#{title}' and its descendants"

    # Now proceed with the actual destruction
    yield
  end

  def generate_slug
    return if slug.present?

    base_slug = title.parameterize
    self.slug = base_slug

    # Handle duplicate slugs within the same parent
    counter = 1
    while Category.where(slug: slug, parent_id: parent_id).where.not(id: id).exists?
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end

  # Update the set_category_type method:
  def set_category_type
    # Calculate depth based on parent chain without assigning it
    current_depth = calculate_depth

    self.category_type = case current_depth
      when 0 then :root
      when 1 then :category
      when 2 then :subcategory
      when 3 then :product
      else :product
      end
  end

  def build_path
    self.path = build_path_string
  end

  def build_path_string
    return slug if parent.nil?

    "#{parent.full_path}/#{slug}"
  end

  def update_children_paths
    children.each do |child|
      child.update_column(:path, child.build_path_string)
      child.send(:update_children_paths)
    end
  end

  def calculate_depth
    return 0 if parent.nil?

    depth_count = 0
    current = parent
    while current
      depth_count += 1
      current = current.parent
      break if depth_count > 10 # Safety check to prevent infinite loops
    end
    depth_count
  end

  def validate_hierarchy_depth
    return unless parent

    calculated_depth = calculate_depth
    if calculated_depth > 3
      errors.add(:parent, "Category hierarchy cannot exceed 4 levels")
    end
  end
end
