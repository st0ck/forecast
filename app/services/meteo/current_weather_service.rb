module Meteo
  # Handles the process of fetching current weather.
  class CurrentWeatherService
    H3_RESOLUTION = 8
    CACHE_EXPIRATION = 30.minutes
    CACHE_PREFIX = 'current_weather'.freeze

    attr_reader :lat, :lon

    def initialize(lat, lon, redis_pool)
      @error = nil
      @lat = lat
      @lon = lon

      cache_handler = CacheHandler.new(
        cache_key: cache_key,
        expiration: CACHE_EXPIRATION,
        redis_pool: redis_pool
      )

      @data_fetcher = DataFetcher.new(
        cache_handler: cache_handler,
        service: build_service,
        data_representer: Meteo::Weather
      )
    end

    def perform
      @data_fetcher.perform
    end

    private

    # Generates a cache key for the given latitude and longitude.
    # @return [String] the cache key.
    def cache_key
      @cache_key ||= "#{CACHE_PREFIX}:#{H3.from_geo_coordinates([lat, lon], H3_RESOLUTION)}"
    end

    # Service for fetching current weather information.
    # @return [Integrations::Meteo::Openweather::CurrentWeather] current weather service
    def build_service
      @service ||= begin
        request_handler = RequestHandler.new
        Integrations::Meteo::Openweather::CurrentWeather.new(lat, lon, request_handler)
      end
    end
  end
end
