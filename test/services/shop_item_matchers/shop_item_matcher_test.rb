require 'test_helper'

class ShopItemMatchers::ShopItemMatcherTest < ActiveSupport::TestCase
  def setup
    @title = 'Test Product Title'
    @sim = 0.5
    @matcher = ShopItemMatchers::ShopItemMatcher.new(title: @title, sim: @sim)
  end

  test 'returns nil if title is blank' do
    matcher = ShopItemMatchers::ShopItemMatcher.new(title: '', sim: @sim)
    assert_nil matcher.find_best_match
  end

  test 'returns nil if pg_trgm is not available' do
    matcher = ShopItemMatchers::ShopItemMatcher.new(title: @title, sim: @sim)
    def matcher.pg_trgm_available?; false; end
    assert_nil matcher.find_best_match
  end

  test 'returns nil if no shop item found' do
    matcher = ShopItemMatchers::ShopItemMatcher.new(title: @title, sim: @sim)
    def matcher.pg_trgm_available?; true; end
    def matcher.find_shop_item_by_title(_title); nil; end
    assert_nil matcher.find_best_match
  end

  test 'returns shop item if found' do
    matcher = ShopItemMatchers::ShopItemMatcher.new(title: @title, sim: @sim)
    matcher.instance_variable_set(:@fake_result, [{ 'uuid' => '123', 'title' => @title }])
    def matcher.pg_trgm_available?; true; end
    def matcher.find_shop_item_by_title(_title); @fake_result; end
    result = matcher.find_best_match
    assert_not_nil result
    assert_equal matcher.instance_variable_get(:@fake_result), result
  end

  test 'find_fuzzy_match returns nil on error' do
    matcher = ShopItemMatchers::ShopItemMatcher.new(title: @title, sim: @sim)
    assert_nil matcher.send(:find_fuzzy_match, 'bad', @sim)
  end

  test 'find_best_match finds shop item by title from fixtures' do
    matcher = ShopItemMatchers::ShopItemMatcher.new(title: 'Organic Milk', sim: 0.1)
    def matcher.pg_trgm_available?; true; end
    result = matcher.find_best_match
    assert result.is_a?(Array), 'Result should be an array of matches'
    assert result.any? { |item| item['title'] == 'Organic Milk' }, 'Should find Organic Milk in results'
    assert result.first['sim_score'] >= 0.1, 'Similarity score should meet threshold'
  end

  test 'find_best_match returns nil for unmatched title' do
    matcher = ShopItemMatchers::ShopItemMatcher.new(title: 'Nonexistent Product', sim: 0.9)
    def matcher.pg_trgm_available?; true; end
    result = matcher.find_best_match
    assert_nil result, 'Should return nil for no match'
  end
end
