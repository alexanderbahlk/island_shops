class ShopItem < ApplicationRecord
  has_many :shop_item_updates, dependent: :destroy
  belongs_to :shop_item_category, optional: true
  belongs_to :shop_item_sub_category, optional: true

  validates :url, presence: true, uniqueness: true
  validates :title, presence: true
  validates :shop, presence: true, inclusion: { in: Shop::ALLOWED }

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
  scope :by_category, ->(category_id) { where(shop_item_category_id: category_id) if category_id.present? }
  scope :by_sub_category, ->(sub_category_id) { where(shop_item_sub_category_id: sub_category_id) if sub_category_id.present? }
  scope :missing_shop_item_category, -> { where(shop_item_category_id: nil) }
  scope :missing_shop_item_sub_category, -> { where(shop_item_sub_category_id: nil) }
  scope :was_manually_updated, -> { where.not(display_title: [nil, ""]).where.not(shop_item_category_id: nil).where.not(shop_item_sub_category_id: nil) }
  # For Ransack search

  def self.ransackable_attributes(auth_object = nil)
    ["approved", "created_at", "display_title", "id", "id_value", "image_url", "location", "product_id", "shop", "size", "title", "updated_at", "url", "unit", "shop_item_type", "shop_item_subtype", "shop_item_category_id", "shop_item_sub_category_id", "needs_another_review"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["shop_item_updates"]
  end

  private

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
