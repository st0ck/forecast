module Integrations
  module Meteo
    module Openweather
      # Implements weather fetching from OpenWeather API.
      class CurrentWeather < Base
        # Initializes the OpenweatherForecast.
        # @param lat [Float] the latitude for the weather query.
        # @param lon [Float] the longitude for the weather query.
        # @param request_handler [RequestHandler] the request handler for making requests.
        def initialize(lat, lon, request_handler)
          @lat = lat
          @lon = lon
          super(request_handler)
        end

        # Fetches current weather for given latitude and longitude.
        # @return [Hash] current weather data containing temperature, description, latitude, and longitude.
        def fetch
          uri = URI("#{BASE_URL}/weather")
          params = {
            lat: @lat,
            lon: @lon,
            appid: @api_key,
            units: 'metric'
          }

          response = @request_handler.make_request(uri, params: params)
          parse_weather_response(response)
        end

        private

        # Parses the response for current weather data.
        # @param response [Net::HTTPResponse] the response object from the HTTP request.
        # @return [Hash] parsed current weather data containing temperature, description, latitude, and longitude.
        def parse_weather_response(response)
          begin
            data = JSON.parse(response.body)
            {
              temperature: data.dig('main', 'temp').round,
              feels_like: data.dig('main', 'feels_like').round,
              status: map_status(data.dig('weather', 0, 'icon')),
              humidity: data.dig('main', 'humidity').round,
              wind_speed: data.dig('wind', 'speed').round,
              date: Time.at(data['dt']).to_date,
              max_temp: data.dig('main', 'temp_max').round,
              min_temp: data.dig('main', 'temp_min').round
            }
          rescue JSON::ParserError => e
            raise "Failed to parse weather response: #{e.message}"
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
