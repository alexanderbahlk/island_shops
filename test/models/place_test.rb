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
require "test_helper"

class LocationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
