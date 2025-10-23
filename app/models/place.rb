# == Schema Information
#
# Table name: places
#
#  id         :bigint           not null, primary key
#  is_online  :boolean          default(FALSE), not null
#  latitude   :decimal(10, 6)
#  location   :string
#  longitude  :decimal(10, 6)
#  title      :string           not null
#  uuid       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_places_on_title  (title)
#  index_places_on_uuid   (uuid) UNIQUE
#
class Place < ApplicationRecord
  has_many :shop_items, dependent: :nullify

  validates :title, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true

  def self.ransackable_associations(auth_object = nil)
    ["shop_items"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "is_online", "location", "title", "updated_at", "uuid", "latitude", "longitude"]
  end

  def has_coordinates?
    latitude.present? && longitude.present?
  end
end
