module Integrations
  module Meteo
    module Openweather
      # Implements weather fetching from OpenWeather API.
      class Forecast < Base
        # Initializes the OpenweatherForecast.
        # @param lat [Float] the latitude for the weather query.
        # @param lon [Float] the longitude for the weather query.
        # @param request_handler [RequestHandler] the request handler for making requests.
        def initialize(lat, lon, request_handler)
          @lat = lat
          @lon = lon
          @request_handler = request_handler
          @api_key = ENV['OPENWEATHER_API_KEY']
        end

        # Fetches 7-day weather forecast for given latitude and longitude.
        # @return [Array<Hash>] 7-day weather forecast data, each containing date, temperature, and description.
        def fetch
          uri = URI("#{BASE_URL}/forecast")
          params = {
            lat: @lat,
            lon: @lon,
            appid: @api_key,
            units: 'metric'
          }

          response = @request_handler.make_request(uri, params: params)
          parse_forecast_response(response)
        end

        private

        # Parses the response for 7-day weather forecast.
        # @param response [Net::HTTPResponse] the response object from the HTTP request.
        # @return [Array<Hash>] parsed weather forecast data, each containing date, temperature, and description.
        def parse_forecast_response(response)
          begin
            data = JSON.parse(response.body)
            group_data_by_date(data['list'])
          rescue JSON::ParserError => e
            raise "Failed to parse forecast response: #{e.message}"
          end
        end

        # Converts the 3-hour data records into 1-day data
        # @param list [Array<Hash>] the list of 3-hour data records
        # @return [Hash] weather forecast data
        def group_data_by_date(list)
          forecasts_by_date = list.group_by { |data| Time.at(data['dt']).to_date }
          daily_forecasts = forecasts_by_date.map do |date, day_data|
            humidities = day_data.map { |data| data.dig('main', 'humidity') }
            wind_speeds = day_data.map { |data| data.dig('wind', 'speed') }
            max_temps = day_data.map { |data| data.dig('main', 'temp_max') }
            min_temps = day_data.map { |data| data.dig('main', 'temp_min') }

            avg_humidity = (humidities.sum / humidities.size).round
            avg_wind_speed = (wind_speeds.sum / wind_speeds.size).round
            daily_max_temp = max_temps.max.round
            daily_min_temp = min_temps.min.round

            status_icons = day_data.map { |data| data.dig('weather', 0, 'icon') }
            most_common_icon = status_icons.group_by(&:itself).values.max_by(&:size).first
            status = map_status(most_common_icon)

            {
              status: status,
              humidity: avg_humidity,
              wind_speed: avg_wind_speed,
              date: date,
              max_temp: daily_max_temp,
              min_temp: daily_min_temp
            }
          end
        end

        # Maps the status description to a unified status.
        # @param description [String] the description from the API response.
        # @return [String] the mapped status.
        def map_status(description)
          STATUS_MAPPING[description] || 'unknown'
        end
      end
    end
  end
end
