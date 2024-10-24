require 'test_helper'

class Geo::AddressLookupServiceTest < ActiveSupport::TestCase
  def setup
    @query = '825 Milwaukee Ave'
    @session_id = 'test_session_id'
    @options = { session_id: @session_id }
    @redis_pool = mock()
    @cache_handler = mock()
    @address_list = Geo::AddressList.new([
      Geo::Address.new(
        name: '825 Milwaukee Ave, Glenview, IL 60025-3715, United States',
        address: '825 Milwaukee Ave, Glenview, IL 60025-3715, United States',
        latitude: 42.07103,
        longitude: -87.85347,
        country: 'United States',
        city: 'Glenview',
        postcode: '60025-3715'
      )
    ])
    @base_result = BaseResult.new(data: @address_list)
  end

  test 'returns the address list when data is successfully fetched' do
    data_fetcher = mock('DataFetcher')
    data_fetcher.expects(:perform).returns(@base_result)
    DataFetcher.stubs(:new).returns(data_fetcher)

    @service = Geo::AddressLookupService.new(
      query: @query,
      options: @options,
      redis_pool: @redis_pool
    )

    result = @service.perform

    assert_equal @base_result, result
    assert_equal @address_list, result.data
    assert_nil result.error
  end

  test 'handles Errors::UnavailableService and returns BaseResult with error' do
    exception = Errors::UnavailableService.new('Service Unavailable')

    data_fetcher = mock('DataFetcher')
    data_fetcher.expects(:perform).raises(Errors::UnavailableService.new('Service Unavailable'))
    DataFetcher.stubs(:new).returns(data_fetcher)

    @service = Geo::AddressLookupService.new(
      query: @query,
      options: @options,
      redis_pool: @redis_pool
    )

    Rails.logger.stubs(:error).returns(nil)
    result = @service.perform

    assert_instance_of BaseResult, result
    assert_nil result.data
    expected_error = I18n.t('.errors.unavailable_service', scope: 'geo.address_lookup_service')
    assert_equal expected_error, result.error
  end

  test 'handles unexpected errors and returns empty BaseResult' do
    data_fetcher = mock('DataFetcher')
    data_fetcher.expects(:perform).raises(StandardError.new('Unexpected error'))
    DataFetcher.stubs(:new).returns(data_fetcher)

    @service = Geo::AddressLookupService.new(
      query: @query,
      options: @options,
      redis_pool: @redis_pool
    )

    Rails.logger.stubs(:error).returns(nil)
    result = @service.perform

    assert_instance_of BaseResult, result
    assert_nil result.data
    assert_nil result.error
  end
end
