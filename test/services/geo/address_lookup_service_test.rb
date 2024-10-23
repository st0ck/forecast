require 'test_helper'

class Geo::AddressLookupServiceTest < ActiveSupport::TestCase
  include RedisTestHelper

  def setup
    setup_redis
    @query = 'Test Address'
    @options = { session_id: 'test_session_id' }
    @redis_pool = Rails.application.config.redis_pool
    @service = Geo::AddressLookupService.new(query: @query, options: @options)
    @address = Geo::Address.new(
      name: '825 Milwaukee Ave, Glenview, IL 60025-3715, United States',
      address: '825 Milwaukee Ave, Glenview, IL 60025-3715, United States',
      latitude: 42.07103,
      longitude: -87.85347,
      country: 'United States',
      city: 'Glenview',
      postcode: '60025-3715'
    )
  end

  def teardown
    teardown_redis
  end

  test 'search returns cached data' do
    cache_key = @service.send(:cache_key)
    @redis_pool.with do |redis|
      redis.set(cache_key, [@address].to_json, ex: 5.minutes)
    end
    result = @service.search

    assert_equal @address.address, result.data.first.address
    assert result.cache_hit, 'Expected cache to be hit'
  end

  test 'search calls service if no cache and caches results' do
    service_mock = mock()
    service_mock.stubs(:fetch).returns([@address])
    @service.stub :service, service_mock do
      result = @service.search

      assert_equal @address.address, result.data.first.address
      assert_not result.cache_hit, 'Expected cache to not be hit'

      cache_key = @service.send(:cache_key)
      cached_value = nil
      @redis_pool.with do |redis|
        cached_value = redis.get(cache_key)
      end
      assert_not_nil cached_value, 'Expected the results to be cached'
      assert_equal [@address].to_json, cached_value
    end
  end

  test 'search logs and returns error on failure' do
    service_mock = mock()
    service_mock.stubs(:fetch).raises(StandardError.new('Test error'))
    @service.stub :service, service_mock do
      Rails.logger.stub :error, nil do
        result = @service.search
        assert_equal 'Internal server error occurred. Please try again later.', result.error
      end
    end
  end

  test 'handle unavailable service error' do
    service_mock = mock()
    service_mock.stubs(:fetch).raises(Errors::UnavailableService.new)

    @service.stub :service, service_mock do
      Rails.logger.stub :error, nil do
        result = @service.search
        assert_equal 'Address lookup service is unavailable.', result.error
        assert_not_nil result.error, 'Expected error logging to be invoked'
      end
    end
  end

  test 'cache key is unique for different queries' do
    cache_key1 = Geo::AddressLookupService.new(query: 'Address1', options: @options).send(:cache_key)
    cache_key2 = Geo::AddressLookupService.new(query: 'Address2', options: @options).send(:cache_key)
    assert_not_equal cache_key1, cache_key2, 'Expected cache keys to be unique for different queries'
  end
end
