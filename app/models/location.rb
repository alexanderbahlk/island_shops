# == Schema Information
#
# Table name: locations
#
#  id          :bigint           not null, primary key
#  description :text
#  is_online   :boolean          default(FALSE), not null
#  title       :string           not null
#  uuid        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_locations_on_title  (title) UNIQUE
#  index_locations_on_uuid   (uuid) UNIQUE
#
class Location < ApplicationRecord
  has_many :shop_items, dependent: :nullify

  validates :title, presence: true, uniqueness: true
end
