# == Schema Information
#
# Table name: shop_items
#
#  id                   :bigint           not null, primary key
#  approved             :boolean          default(FALSE)
#  breadcrumb           :string
#  display_title        :string
#  image_url            :string
#  location             :string
#  needs_another_review :boolean          default(FALSE)
#  shop                 :string           not null
#  size                 :decimal(10, 2)
#  title                :string           not null
#  unit                 :string
#  url                  :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  category_id          :bigint
#  product_id           :string
#
# Indexes
#
#  index_shop_items_on_breadcrumb   (breadcrumb)
#  index_shop_items_on_category_id  (category_id)
#  index_shop_items_on_url          (url) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#
class ShopItem < ApplicationRecord
  has_many :shop_item_updates, dependent: :destroy
  belongs_to :category, optional: true

  validates :url, presence: true, uniqueness: true
  validates :title, presence: true
  validates :shop, presence: true, inclusion: { in: Shop::ALLOWED }
  validates :category, presence: true, if: -> { category_id.present? }
  validate :category_must_be_product, if: -> { category.present? }

  # Optional validations
  validates :image_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true

  # Callbacks
  before_validation :parse_and_set_unit_from_title, if: :title_changed?
  #Does not run on create, only when unit is changed
  before_validation :force_valid_unit_value, if: :unit_changed?, unless: -> { unit.blank? }

  # Scopes
  scope :approved, -> { where(approved: true) }
  scope :pending_approval, -> { where(approved: false) }
  scope :needs_review, -> { where(needs_another_review: true) }
  scope :by_shop, ->(shop_name) { where(shop: shop_name) if shop_name.present? }
  scope :by_category, ->(category_id) { where(category_id: category_id) if category_id.present? }
  scope :in_category, ->(category) { where(category: category) }
  scope :missing_category, -> { where(category_id: nil) }
  scope :under_category_path, ->(path) {
          joins(:category).where("categories.path LIKE ?", "#{path}%")
        }
  scope :was_manually_updated, -> { where.not(display_title: [nil, ""]).where.not(category_id: nil) }
  scope :no_price_per_unified_unit, -> {
          # Items with no updates at all OR items where the latest update has no price_per_unit
          where(
            id: ShopItem.left_joins(:shop_item_updates)
                        .where(shop_item_updates: { id: nil })
                        .select(:id),
          ).or(
                          where(
                            id: ShopItem.joins(:shop_item_updates)
                                        .where(shop_item_updates: { price_per_unit: nil })
                                        .where(
                                          shop_item_updates: {
                                            id: ShopItemUpdate.select("MAX(id)")
                                                              .where("shop_item_updates.shop_item_id = shop_items.id")
                                                              .group(:shop_item_id),
                                          },
                                        )
                                        .select(:id),
                          )
                        )
        }

  # For Ransack search
  def self.ransackable_attributes(auth_object = nil)
    ["approved", "created_at", "display_title", "id", "id_value", "image_url", "location", "product_id", "shop", "size", "title", "updated_at", "url", "unit", "category_id", "needs_another_review"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["shop_item_updates", "category"]
  end

  def self.ransackable_scopes(auth_object = nil)
    [:no_price_per_unified_unit]
  end

  def latest_price_per_unified_unit
    latest_update = self.shop_item_updates.order(created_at: :desc).first
    if latest_update&.price_per_unit
      "$" + latest_update.price_per_unit.to_s + " per " + latest_update.normalized_unit.to_s
    else
      "N/A"
    end
  end

  def latest_price_per_unit
    latest_update = self.shop_item_updates.order(created_at: :desc).first
    if latest_update&.price && self.unit.present?
      self.size.to_s + self.unit.to_s + " for $" + latest_update.price.to_s
    else
      "N/A"
    end
  end

  def category_hierarchy
    return {} unless category

    breadcrumbs = category.breadcrumbs
    {
      root: breadcrumbs[0]&.title,
      category: breadcrumbs[1]&.title,
      subcategory: breadcrumbs[2]&.title,
      product: breadcrumbs[3]&.title,
    }
  end

  def category_path
    category&.full_path
  end

  def set_shop_product_from_text(text)
    if text.present?
      # Try to find existing Category or create new one
      category = Category.find_or_create_by(title: text.strip)
      self.category = category
    elsif text.blank?
      self.category = nil
    end
  end

  def no_price_per_unified_unit
    latest_update = self.shop_item_updates.order(created_at: :desc).first
    latest_update.nil? || latest_update.price_per_unit.nil?
  end

  private

  def category_must_be_product
    unless category.product?
      errors.add(:category, "must be a product category (level 4)")
    end
  end

  def force_valid_unit_value
    #call UnitParser.normalize_unit to ensure unit is valid
    normalized = UnitParser.normalize_unit(unit)
    if normalized.nil?
      errors.add(:unit, "is not a recognized unit")
    else
      self.unit = normalized
    end
  end

  def parse_and_set_unit_from_title
    return unless title.present?

    parsed_data = UnitParser.parse_from_title(title)

    # Only set if current values are blank
    self.size = parsed_data[:size] if size.blank? && parsed_data[:size].present?
    self.unit = parsed_data[:unit] if unit.blank? && parsed_data[:unit].present?
  end
end
