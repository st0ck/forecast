class DataFetcher
  attr_reader :cache_handler, :service, :data_representer

  def initialize(cache_handler:, service:, data_representer:)
    @cache_handler = cache_handler
    @service = service
    @data_representer = data_representer
  end

  # Attempts to fetch data from the cache or service.
  # If cached data is found, it is returned with a cache hit indicator.
  # If no cache is found, the service is called to fetch fresh data, which is then cached and returned.
  # @return [BaseResult] the result containing the fetched data, cache status, and any errors.
  def perform
    cached_data = fetch_from_cache
    return cached_data if cached_data.cache_hit

    fetch_from_service
  end

  private

  # Attempts to fetch data from the cache.
  # If cached data is found, it is returned with the cache hit status and age of the cache.
  # If no cached data is found, a BaseResult with no data is returned.
  # @return [BaseResult] the result containing cached data or an empty result if no cache is found.
  def fetch_from_cache
    cached_value = cache_handler.get
    return BaseResult.new unless cached_value

    data = data_representer.from_data(cached_value)
    age = cache_handler.age
    BaseResult.new(data: data, cache_hit: true, cache_age: age)
  end

  # Fetches fresh data from the service and caches the result.
  # If the service returns valid data, the result is cached and returned.
  # If no data is returned, an empty BaseResult is returned.
  # @return [BaseResult] the result containing fresh data or an empty result if no data is fetched.
  def fetch_from_service
    results = service.fetch
    return BaseResult.new unless results.present?

    cache_handler.set(results)
    data = data_representer.from_data(results)
    BaseResult.new(data: data)
  end
end
