require 'test_helper'

class CacheHandlerTest < ActiveSupport::TestCase
  include RedisTestHelper

  def setup
    setup_redis
    @cache_key = 'test_cache_key'
    @expiration = 300
    @cache_handler = CacheHandler.new(
      cache_key: @cache_key,
      expiration: @expiration,
      redis_pool: redis_pool
    )
    @data = { 'name' => 'test', 'value' => 123 }
  end

  def teardown
    teardown_redis
  end

  test 'get retrieves data from redis and parses JSON' do
    @cache_handler.set(@data)
    assert_equal @data, @cache_handler.get
  end

  test 'get returns nil if data does not exist in redis' do
    assert_nil @cache_handler.get
  end

  test 'set stores data in redis as JSON' do
    result = @cache_handler.set(@data)
    assert result
    assert_equal @data, @cache_handler.get
  end

  test 'ttl retrieves ttl value from redis' do
    @cache_handler.set(@data)
    result = @cache_handler.ttl
    assert result <= @expiration
  end

  test 'age calculates the correct age based on ttl and expiration' do
    @cache_handler = CacheHandler.new(
      cache_key: @cache_key,
      expiration: 200,
      redis_pool: redis_pool
    )
    @cache_handler.set(@data)
    ttl = @cache_handler.ttl
    result = @cache_handler.age
    assert_equal 200 - ttl, result
  end

  test 'age returns nil if expiration is nil' do
    @cache_handler = CacheHandler.new(
      cache_key: @cache_key,
      expiration: nil,
      redis_pool: redis_pool
    )
    @cache_handler.set(@data)
    result = @cache_handler.age
    assert_nil result
  end
end
