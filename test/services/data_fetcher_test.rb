require 'test_helper'

class DataFetcherTest < ActiveSupport::TestCase
  test 'returns cached data when available' do
    cached_value = { 'some' => 'data' }
    data_object = 'data_object'
    age = 100

    cache_handler = Object.new
    def cache_handler.get
      { 'some' => 'data' }
    end

    def cache_handler.age
      100
    end

    data_representer = Object.new
    def data_representer.from_data(data)
      'data_object'
    end

    service = Object.new

    data_fetcher = DataFetcher.new(
      cache_handler: cache_handler,
      service: service,
      data_representer: data_representer
    )

    result = data_fetcher.perform

    assert_equal 'data_object', result.data
    assert result.cache_hit, 'Expected cache_hit to be true'
    assert_equal 100, result.cache_age
  end

  test 'fetches data when no cached data is available' do
    fetched_results = { 'some' => 'fetched_data' }
    data_object = 'data_object'

    cache_handler = Object.new
    def cache_handler.get
      nil
    end

    def cache_handler.set(data)
    end

    service = Object.new
    def service.fetch
      { 'some' => 'fetched_data' }
    end

    data_representer = Object.new
    def data_representer.from_data(data)
      'data_object'
    end

    data_fetcher = DataFetcher.new(
      cache_handler: cache_handler,
      service: service,
      data_representer: data_representer
    )

    result = data_fetcher.perform

    assert_equal 'data_object', result.data
    assert_not result.cache_hit, 'Expected cache_hit to be false'
    assert_nil result.cache_age
  end

  test 'returns empty result when service returns no data' do
    cache_handler = Object.new
    def cache_handler.get
      nil
    end

    service = Object.new
    def service.fetch
      nil
    end

    data_representer = Object.new

    data_fetcher = DataFetcher.new(
      cache_handler: cache_handler,
      service: service,
      data_representer: data_representer
    )

    result = data_fetcher.perform

    assert_nil result.data
    assert_not result.cache_hit, 'Expected cache_hit to be false'
    assert_nil result.cache_age
  end

  test 'raises exception when service.fetch raises exception' do
    cache_handler = Object.new
    def cache_handler.get
      nil
    end

    service = Object.new
    def service.fetch
      raise StandardError.new('Service fetch failed')
    end

    data_representer = Object.new

    data_fetcher = DataFetcher.new(
      cache_handler: cache_handler,
      service: service,
      data_representer: data_representer
    )

    exception = assert_raises StandardError do
      data_fetcher.perform
    end
    assert_equal 'Service fetch failed', exception.message
  end

  test 'raises exception when data_representer.from_data raises exception' do
    cache_handler = Object.new
    def cache_handler.get
      { 'some' => 'data' }
    end

    def cache_handler.age
      100
    end

    data_representer = Object.new
    def data_representer.from_data(data)
      raise StandardError.new('Data representation failed')
    end

    service = Object.new

    data_fetcher = DataFetcher.new(
      cache_handler: cache_handler,
      service: service,
      data_representer: data_representer
    )

    exception = assert_raises StandardError do
      data_fetcher.perform
    end
    assert_equal 'Data representation failed', exception.message
  end
end
