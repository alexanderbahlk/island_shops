class ShopItem < ApplicationRecord
  has_many :shop_item_updates, dependent: :destroy
  belongs_to :shop_item_category, optional: true
  belongs_to :shop_item_sub_category, optional: true

  validates :url, presence: true, uniqueness: true
  validates :title, presence: true
  validates :shop, presence: true, inclusion: { in: Shop::ALLOWED }

  # Optional validations
  validates :image_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true

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
end
