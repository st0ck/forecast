require 'test_helper'

class Api::V1::Meteo::CurrentWeatherControllerTest < ActionDispatch::IntegrationTest
  include RedisTestHelper

  def setup
    setup_redis
    @lat = 42.07103
    @lon = -87.85347
    @invalid_lat = 100.0    # Invalid latitude
    @invalid_lon = -200.0   # Invalid longitude
    @weather_data = {
      temperature: 22.0,
      feels_like: 21.5,
      status: 'clear',
      humidity: 50,
      wind_speed: 5.5,
      date: '2024-10-23',
      max_temp: 23.0,
      min_temp: 20.0
    }
  end

  def teardown
    teardown_redis
  end

  test 'should return successful response with current weather data from cache' do
    cache_key = "current_weather:#{H3.from_geo_coordinates([@lat, @lon], 8)}"
    redis_pool.with do |redis|
      redis.set(cache_key, @weather_data.to_json, ex: 30.minutes)
    end

    post api_v1_meteo_current_weather_index_url, params: { current_weather: { lat: @lat, lon: @lon } }, as: :json

    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal @weather_data[:temperature], response_data['data']['temperature']
    assert_nil response_data['errors'], 'Expected no errors'
  end

  test 'should return error for invalid latitude and longitude' do
    post api_v1_meteo_current_weather_index_url, params: { current_weather: { lat: @invalid_lat, lon: @invalid_lon } }, as: :json

    assert_response :bad_request
    response_data = JSON.parse(response.body)
    assert response_data['errors'].any?, 'Expected errors for invalid geolocation'
    error_message = response_data['errors'].first['message']
    assert_includes error_message, 'Lat must be less than or equal to 90'
    assert_includes error_message, 'Lon must be greater than or equal to -180'
  end

  test 'should handle non-numeric latitude and longitude' do
    post api_v1_meteo_current_weather_index_url, params: { current_weather: { lat: '0', lon: '0' } }, as: :json

    assert_response :bad_request
    response_data = JSON.parse(response.body)
    assert response_data['errors'].any?, 'Expected errors for non-numeric geolocation'
    error_message = response_data['errors'].first['message']
    assert_includes error_message, 'Lat is not a number'
    assert_includes error_message, 'Lon is not a number'
  end

  test 'should handle missing parameters' do
    post api_v1_meteo_current_weather_index_url, params: { current_weather: { lat: @lat } }, as: :json

    assert_response :bad_request
    response_data = JSON.parse(response.body)
    assert response_data['errors'].any?, 'Expected errors for missing parameter'
    errors = response_data['errors'].map { |err| err['message'] }
    assert_includes errors, 'param is missing or the value is empty: lon'
  end

  test 'should handle service error gracefully' do
    Meteo::CurrentWeatherService.any_instance.stubs(:perform).returns(BaseResult.new(error: 'Service error'))

    post api_v1_meteo_current_weather_index_url, params: { current_weather: { lat: @lat, lon: @lon } }, as: :json

    assert_response :internal_server_error
    response_data = JSON.parse(response.body)
    assert response_data['errors'].any?, 'Expected error response'
    assert_equal 'Service error', response_data['errors'].first['message']
  end

  test 'should handle too many requests error' do
    Meteo::CurrentWeatherService.any_instance.stubs(:perform).raises(Errors::TooManyRequests.new(retry_after: 11))

    post api_v1_meteo_current_weather_index_url, params: { current_weather: { lat: @lat, lon: @lon } }, as: :json

    assert_response :too_many_requests
    response_data = JSON.parse(response.body)
    assert response_data['errors'].any?, 'Expected error response'
    assert_equal 'Too Many Requests. Try again in 11 seconds.', response_data['errors'].first['message']
    assert_equal 11, response.headers['Retry-After']
  end

  test 'should handle data not found error' do
    Meteo::CurrentWeatherService.any_instance.stubs(:perform).returns(BaseResult.new(data: nil, error: 'Data not found'))

    post api_v1_meteo_current_weather_index_url, params: { current_weather: { lat: @lat, lon: @lon } }, as: :json

    assert_response :internal_server_error
    response_data = JSON.parse(response.body)
    assert response_data['errors'].any?, 'Expected error response'
    assert_equal 'Data not found', response_data['errors'].first['message']
  end
end
