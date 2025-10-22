# == Schema Information
#
# Table name: places
#
#  id         :bigint           not null, primary key
#  is_online  :boolean          default(FALSE), not null
#  location   :string
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

  def self.ransackable_associations(auth_object = nil)
    ["shop_items"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "is_online", "location", "title", "updated_at", "uuid"]
  end
end
