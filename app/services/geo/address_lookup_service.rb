module Geo
  class AddressLookupService
    CACHE_PREFIX = 'geo:address_lookup'.freeze
    CACHE_EXPIRATION = 5.minutes

    # Initialize the AddressLookupService with a query, options, and optional redis_pool
    # @param query [String] the query to search for an address
    # @param options [Hash] additional options, must include :session_id
    # @param redis_pool [ConnectionPool] Redis connection pool
    def initialize(query:, options:, redis_pool: Rails.application.config.redis_pool)
      @query = query
      @session_id = options[:session_id]
      cache_handler = CacheHandler.new(
        cache_key: cache_key,
        expiration: CACHE_EXPIRATION,
        redis_pool: redis_pool
      )
      @data_fetcher = DataFetcher.new(
        cache_handler: cache_handler,
        service: build_service,
        data_representer: Geo::AddressList
      )
    end

    # Perform the address lookup search
    # @return [BaseResult] contains either cached or fetched data or an error
    def perform
      @data_fetcher.perform
    rescue Errors::UnavailableService => ex
      log_exception(ex)
      BaseResult.new(error: i18n('.errors.unavailable_service'))
    rescue StandardError => ex
      log_exception(ex)
      BaseResult.new
    end

    private

    # Generate a unique cache key for the query
    # @return [String] the cache key for the query
    def cache_key
      @cache_key ||= "#{CACHE_PREFIX}:#{Digest::SHA256.hexdigest(@query)}"
    end

    # Retrieve the external address lookup service instance
    # @return [Integrations::Geo::Mapbox::AddressLookup] the address lookup service instance
    def build_service
      request_handler = RequestHandler.new
      Integrations::Geo::Mapbox::AddressLookup.new(
        query: @query,
        session_token: @session_id,
        request_handler: request_handler
      )
    end

    # Log an exception
    # @param exception [Exception] the exception to log
    def log_exception(exception)
      Rails.logger.error(exception.message)
      Rails.logger.error(exception.backtrace.join("\n\t"))
    end

    # Translate the error message using I18n
    # @param key [String] the translation key
    # @return [String] the localized error message
    def i18n(key)
      I18n.t(key, scope: 'geo.address_lookup_service')
    end
  end
end
