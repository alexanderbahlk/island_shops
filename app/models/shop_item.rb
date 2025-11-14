# == Schema Information
#
# Table name: shop_items
#
#  id                           :bigint           not null, primary key
#  approved                     :boolean          default(FALSE)
#  breadcrumb                   :string
#  display_title                :string
#  image_url                    :string
#  model_embedding              :jsonb
#  needs_another_review         :boolean          default(FALSE)
#  needs_model_embedding_update :boolean          default(FALSE), not null
#  size                         :decimal(10, 2)
#  title                        :string           not null
#  unit                         :string
#  url                          :string           not null
#  uuid                         :uuid             not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  category_id                  :bigint
#  place_id                     :bigint
#  product_id                   :string
#  user_id                      :bigint
#
# Indexes
#
#  index_shop_items_on_approved         (approved)
#  index_shop_items_on_breadcrumb       (breadcrumb)
#  index_shop_items_on_category_id      (category_id)
#  index_shop_items_on_model_embedding  (model_embedding) USING gin
#  index_shop_items_on_place_id         (place_id)
#  index_shop_items_on_url              (url) UNIQUE
#  index_shop_items_on_user_id          (user_id)
#  index_shop_items_on_uuid             (uuid) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (place_id => places.id)
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
class ShopItem < ApplicationRecord
  has_many :shopping_list_items, dependent: :nullify
  has_many :shop_item_updates, dependent: :destroy
  belongs_to :category, optional: true
  belongs_to :place, optional: true # Optional for now to allow migration of existing data
  belongs_to :user, optional: true # Optional association

  validates :url, presence: true, uniqueness: true
  validates :title, presence: true
  validates :category, presence: true, if: -> { category_id.present? }
  validates :place, presence: true, if: -> { place_id.present? }
  validate :category_must_be_product, if: -> { category.present? }
  validates :uuid, uniqueness: true

  # Optional validations
  validates :image_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true

  # Callbacks
  # Parse and set unit from title
  before_validation :parse_and_set_unit_from_title, if: :title_changed?

  # needs_model_embedding_update = true if title or breadcrumb changes
  before_save :set_needs_model_embedding_update, if: -> { title_changed? || breadcrumb_changed? }
  #
  #Does not run on create, only when unit is changed
  before_validation :force_valid_unit_value, if: :unit_changed?, unless: -> { unit.blank? }

  before_destroy :clear_shopping_list_item_references

  # Scopes
  scope :approved, -> { where(approved: true) }
  scope :pending_approval, -> { where(approved: false) }
  scope :pending_approval_with_category, -> { where(approved: false).where.not(category_id: nil) }
  scope :needs_ai_category_match, -> { where(approved: false).where.not(model_embedding: nil) }
  scope :needs_model_embedding_update, -> { where(needs_model_embedding_update: true).or(where(model_embedding: nil)) }
  scope :needs_review, -> { where(needs_another_review: true) }
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
  scope :no_unit_size, -> {
          where(unit: [nil, ""]).or(where(size: nil))
        }
  scope :is_community_report, -> {
          where.not(user_id: nil)
        }

  # For Ransack search
  def self.ransackable_attributes(auth_object = nil)
    ["approved", "created_at", "display_title", "id", "id_value", "image_url", "product_id", "size", "title", "updated_at", "url", "unit", "category_id", "needs_another_review", "breadcrumb", "place_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["shop_item_updates", "category"]
  end

  def self.ransackable_scopes(auth_object = nil)
    [:no_price_per_unified_unit]
  end

  def latest_price_per_unit_with_unit
    latest_update = latest_shop_item_update
    if latest_update&.price && self.unit.present?
      self.size.to_s + self.unit.to_s + " for $" + latest_update.price.to_s
    else
      "N/A"
    end
  end

  def latest_price_per_normalized_unit
    latest_update = latest_shop_item_update
    if latest_update&.price_per_unit && latest_update&.price_per_unit.is_a?(Numeric)
      latest_update.price_per_unit
    else
      "N/A"
    end
  end

  def latest_price_per_normalized_unit_with_unit
    latest_price_per_normalized_unit = latest_price_per_normalized_unit()
    if latest_price_per_normalized_unit && latest_price_per_normalized_unit.is_a?(Numeric)
      "$" + sprintf("%.2f", latest_shop_item_update.price_per_unit).to_s + " per " + latest_shop_item_update.normalized_unit.to_s
    else
      "N/A"
    end
  end

  def latest_stock_status_out_of_stock?
    latest_update = latest_shop_item_update
    latest_update&.out_of_stock? || false
  end

  def latest_stock_status
    latest_update = latest_shop_item_update
    latest_update&.normalized_stock_status || "N/A"
  end

  def latest_shop_item_update
    self.shop_item_updates.order(created_at: :desc).first
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

  def set_needs_model_embedding_update
    self.needs_model_embedding_update = true
  end

  def clear_shopping_list_item_references
    ShoppingListItem.with_deleted.where(shop_item_id: self.id).update_all(shop_item_id: nil)
  end

  def category_must_be_product
    unless category.product?
      errors.add(:category, "must be a product category")
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
    self.size = parsed_data[:size] if (size.blank? || size == 0) && parsed_data[:size].present?
    self.unit = parsed_data[:unit] if (unit.blank? || unit == "N/A") && parsed_data[:unit].present?
  end
end
