# == Schema Information
#
# Table name: users
#
#  id         :bigint           not null, primary key
#  app_hash   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "test_helper"

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  def setup
    @user = users(:user_one)
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "hash should be present" do
    @user.app_hash = nil
    assert_not @user.valid?
  end

  test "hash should be unique" do
    duplicate_user = @user.dup
    assert_not duplicate_user.valid?
  end
end
