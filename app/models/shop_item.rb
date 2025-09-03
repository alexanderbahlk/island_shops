class ShopItem < ApplicationRecord
  has_many :shop_item_updates, dependent: :destroy

  validates :url, presence: true, uniqueness: true
  validates :title, presence: true
  validates :shop, presence: true, inclusion: { in: Shop::ALLOWED }
  
  # Optional validations
  validates :image_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true

  scope :approved, -> { where(approved: true) }
  scope :pending_approval, -> { where(approved: false) }

  def self.ransackable_attributes(auth_object = nil)
    ["approved", "created_at", "display_title", "id", "id_value", "image_url", "location", "product_id", "shop", "size", "title", "updated_at", "url"]
  end
end
