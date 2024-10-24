require 'test_helper'

class Api::V1::Geo::AddressControllerTest < ActionDispatch::IntegrationTest
  include RedisTestHelper

  def setup
    setup_redis
    @query = '123 Main St'
    @session_id = 'test_session'
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

  test 'should return successful response with address data from cache' do
    cache_key = "geo:address_lookup:#{Digest::SHA256.hexdigest(@query)}"

    redis_pool.with do |redis|
      redis.set(cache_key, [@address].to_json, ex: 5.minutes)
    end

    get api_v1_geo_address_index_url, params: { q: @query, session_id: @session_id }

    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal @address.address, response_data['data'].first['address']
    assert_nil response_data['errors'], 'Expected no errors'
  end

  test 'should return successful response when data is fetched from service' do
    Geo::AddressLookupService.any_instance.stubs(:perform).returns(BaseResult.new(data: [@address]))

    get api_v1_geo_address_index_url, params: { q: '456 Elm St', session_id: @session_id }

    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal @address.address, response_data['data'].first['address']
    assert_nil response_data['errors'], 'Expected no errors'
  end

  test 'should handle missing parameters' do
    get api_v1_geo_address_index_url, params: { q: @query }

    assert_response :bad_request
    response_data = JSON.parse(response.body)
    assert response_data['errors'].any?, 'Expected errors for missing parameter'
    errors = response_data['errors'].map { |err| err['message'] }
    assert_includes errors, 'param is missing or the value is empty: session_id'
  end

  test 'should handle service error gracefully' do
    Geo::AddressLookupService.any_instance.stubs(:perform).returns(BaseResult.new(error: 'Service error'))

    get api_v1_geo_address_index_url, params: { q: @query, session_id: @session_id }

    assert_response :internal_server_error
    response_data = JSON.parse(response.body)
    assert response_data['errors'].any?, 'Expected error response'
    assert_equal 'Service error', response_data['errors'].first['message']
  end

  test 'should handle too many requests error' do
    Geo::AddressLookupService.any_instance.stubs(:perform).raises(Errors::TooManyRequests.new(retry_after: 11))

    get api_v1_geo_address_index_url, params: { q: @query, session_id: @session_id }

    assert_response :too_many_requests
    response_data = JSON.parse(response.body)
    assert response_data['errors'].any?, 'Expected error response'
    assert_equal 'Too Many Requests. Try again in 11 seconds.', response_data['errors'].first['message']
    assert_equal 11, response.headers['Retry-After']
  end
end
