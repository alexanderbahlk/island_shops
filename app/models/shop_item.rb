class ShopItem < ApplicationRecord
  has_many :shop_item_updates, dependent: :destroy

  validates :url, presence: true, uniqueness: true
  validates :title, presence: true
  validates :shop, presence: true
  
  # Optional validations
  validates :image_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true
end
