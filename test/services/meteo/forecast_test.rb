require 'test_helper'

class Meteo::ForecastTest < ActiveSupport::TestCase
  def setup
    @valid_forecast_data = [
      {
        temperature: 22.0,
        feels_like: 21.5,
        status: 'clear',
        humidity: 50,
        wind_speed: 5.5,
        date: '2024-10-23',
        max_temp: 23.0,
        min_temp: 20.0
      },
      {
        temperature: 18.0,
        feels_like: 17.0,
        status: 'partly_cloudy',
        humidity: 60,
        wind_speed: 4.0,
        date: '2024-10-24',
        max_temp: 19.0,
        min_temp: 16.0
      }
    ]
    @invalid_forecast_data = [
      { temperature: nil, feels_like: nil, status: nil, humidity: nil, wind_speed: nil, date: nil }
    ]
  end

  test 'from_data creates a list of weather objects from valid forecast data' do
    forecast = Meteo::Forecast.from_data(@valid_forecast_data)
    assert_equal 2, forecast.size

    first_day = forecast.first
    assert_equal 22.0, first_day.temperature
    assert_equal 21.5, first_day.feels_like
    assert_equal 'clear', first_day.status
    assert_equal 50, first_day.humidity
    assert_equal 5.5, first_day.wind_speed
    assert_equal '2024-10-23', first_day.date
    assert_equal 23.0, first_day.max_temp
    assert_equal 20.0, first_day.min_temp
  end

  test 'from_data handles empty forecast data' do
    forecast = Meteo::Forecast.from_data([])
    assert_equal 0, forecast.size
  end

  test 'from_data handles invalid forecast data' do
    assert_raises(ArgumentError, 'Expected an array of weather data') do
      Meteo::Forecast.from_data(nil)
    end

    assert_raises(ArgumentError, 'Expected each record to be a hash') do
      Meteo::Forecast.from_data([nil])
    end
  end
end
