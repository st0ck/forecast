module Geo
  class AddressLookupService
    CACHE_PREFIX = 'geo:address_lookup'.freeze

    attr_reader :query

    # Initialize the AddressLookupService with a query, options, and optional redis_pool
    # @param query [String] the query to search for an address
    # @param options [Hash] additional options, must include :session_id
    # @param redis_pool [ConnectionPool] Redis connection pool
    def initialize(query:, options:, redis_pool: Rails.application.config.redis_pool)
      @query = query
      @redis_pool = redis_pool
      @session_id = options[:session_id]
    end

    # Perform the address lookup search
    # @return [BaseResult] contains either cached or fetched data or an error
    def search
      return cashed_data if cashed_data.cache_hit

      fetch_from_service
    rescue StandardError => ex
      log_exception(ex)
      BaseResult.new(error: i18n('.errors.internal_error'))
    end

    private

    # Retrieve the cached data from Redis if available
    # @return [BaseResult] returns cached addresses wrapped in BaseResult
    def cashed_data
      @cashed_data ||= begin
        cache_key_with_session = cache_key

        cached_value = @redis_pool.with do |redis|
          redis.get(cache_key_with_session)
        end

        return BaseResult.new unless cached_value.present?

        addresses = JSON.parse(cached_value).map { |address| Geo::Address.new(**address.symbolize_keys) }
        BaseResult.new(data: addresses, cache_hit: true)
      end
    end

    # Cache the results from the address lookup service
    # @param results [Array] the results to be cached
    def cache_results(results)
      cache_key_with_session = cache_key
      @redis_pool.with do |redis|
        redis.set(cache_key_with_session, results.to_json, ex: 5.minutes)
      end
    end

    # Generate a unique cache key for the query
    # @return [String] the cache key for the query
    def cache_key
      @cache_key ||= "#{CACHE_PREFIX}:#{Digest::SHA256.hexdigest(query)}"
    end

    # Fetch address results from the external service
    # @return [BaseResult] contains the fetched data or an error
    def fetch_from_service
      results = service.fetch(query)

      if results.any?
        cache_results(results)
        BaseResult.new(data: results)
      end
    rescue Errors::UnavailableService => ex
      log_exception(ex)
      BaseResult.new(error: i18n('.errors.unavailable_service'))
    end

    # Retrieve the external address lookup service instance
    # @return [Geo::Integrations::BaseAddressLookup] the address lookup service instance
    def service
      @service ||= begin
        request_handler = RequestHandler.new
        Geo::Integrations::MapboxAddressLookup.new(request_handler, @session_id)
      end
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
