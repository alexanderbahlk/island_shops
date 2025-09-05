# == Schema Information
#
# Table name: shop_items
#
#  id                   :bigint           not null, primary key
#  approved             :boolean          default(FALSE)
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
#  product_id           :string
#  shop_item_type_id    :bigint
#
# Indexes
#
#  index_shop_items_on_shop_item_type_id  (shop_item_type_id)
#  index_shop_items_on_url                (url) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (shop_item_type_id => shop_item_types.id)
#
class ShopItem < ApplicationRecord
  has_many :shop_item_updates, dependent: :destroy
  belongs_to :shop_item_type, optional: true

  validates :url, presence: true, uniqueness: true
  validates :title, presence: true
  validates :shop, presence: true, inclusion: { in: Shop::ALLOWED }

  # Optional validations
  validates :image_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true

  # Callbacks
  before_validation :parse_and_set_unit_from_title, if: :title_changed?
  #Does not run on create, only when unit is changed
  before_validation :force_valid_unit_value, if: :unit_changed?, unless: -> { unit.blank? }

  # Virtual attribute for the autocomplete field
  attr_accessor :shop_item_type_title

  # Scopes
  scope :approved, -> { where(approved: true) }
  scope :pending_approval, -> { where(approved: false) }
  scope :needs_review, -> { where(needs_another_review: true) }
  scope :by_shop, ->(shop_name) { where(shop: shop_name) if shop_name.present? }
  scope :by_type, ->(type_id) { where(shop_item_type_id: type_id) if type_id.present? }
  scope :missing_shop_item_type, -> { where(shop_item_type_id: nil) }
  scope :was_manually_updated, -> { where.not(display_title: [nil, ""]).where.not(shop_item_type_id: nil) }

  # For Ransack search
  def self.ransackable_attributes(auth_object = nil)
    ["approved", "created_at", "display_title", "id", "id_value", "image_url", "location", "product_id", "shop", "size", "title", "updated_at", "url", "unit", "shop_item_type_id", "needs_another_review"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["shop_item_updates", "shop_item_type"]
  end

  def latest_price_per_unit
    latest_update = self.shop_item_updates.order(created_at: :desc).first
    if latest_update&.price_per_unit
      "$" + latest_update.price_per_unit.to_s + " per " + latest_update.normalized_unit.to_s
    else
      "N/A"
    end
  end

  # Helper methods to get category and subcategory through type
  def shop_item_category
    shop_item_type&.shop_item_sub_categories&.first&.shop_item_category
  end

  def shop_item_sub_category
    shop_item_type&.shop_item_sub_categories&.first
  end

  private

  def set_shop_item_type_from_title
    if shop_item_type_title.present?
      # Try to find existing type or create new one
      type = ShopItemType.find_or_create_by(title: shop_item_type_title.strip)
      self.shop_item_type = type
    elsif shop_item_type_title.blank?
      self.shop_item_type = nil
    end
  end

  def shop_item_type_title_changed?
    @shop_item_type_title_changed || false
  end

  def shop_item_type_title=(value)
    @shop_item_type_title_changed = true
    @shop_item_type_title = value
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
