class CacheHandler
  attr_reader :redis_pool, :cache_key, :expiration

  def initialize(cache_key:, expiration:, redis_pool: Rails.application.config.redis_pool)
    @cache_key = cache_key
    @redis_pool = redis_pool
    @expiration = expiration
  end

  # Initializes a new CacheHandler object with a cache key, expiration time, and Redis connection pool.
  # @param cache_key [String] the key to use for storing and retrieving cached data.
  # @param expiration [Integer] the expiration time for the cached data in seconds.
  # @param redis_pool [ConnectionPool] the Redis connection pool (default: Rails.application.config.redis_pool).
  def initialize(cache_key:, expiration:, redis_pool: Rails.application.config.redis_pool)
    @cache_key = cache_key
    @redis_pool = redis_pool
    @expiration = expiration
  end

  # Retrieves cached data from Redis.
  # @return [Object, NilClass] the parsed JSON data from Redis, or nil if no data is found.
  def get
    redis_pool.with do |redis|
      data = redis.get(cache_key)
      JSON.parse(data) if data
    end
  end

  # Stores data in Redis with the specified expiration time.
  # @param data [Object] the data to cache.
  # @param options [Hash] additional Redis options (e.g., expiration time).
  # @return [Boolean] true if the data was successfully stored, false otherwise.
  def set(data, **options)
    redis_options = { ex: expiration }.merge(options)
    result = redis_pool.with do |redis|
      redis.set(cache_key, data.to_json, **redis_options)
    end

    result == 'OK'
  end

  # Retrieves the time-to-live (TTL) of the cached data.
  # @return [Integer] the remaining TTL in seconds.
  def ttl
    redis_pool.with { |redis| redis.ttl(cache_key) }
  end

  # Calculates the age of the cached data in seconds based on its TTL.
  # @return [Integer, NilClass] the age of the cached data in seconds, or nil if no expiration is set.
  def age
    return nil if expiration.nil?
    ttl_value = ttl
    return nil if ttl_value.nil? || ttl_value <= 0
    expiration - ttl_value
  end
end
