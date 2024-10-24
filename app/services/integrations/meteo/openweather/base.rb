module Integrations
  module Meteo
    module Openweather
      # Base class for OpenWeather API.
      class Base
        BASE_URL = 'https://api.openweathermap.org/data/2.5'.freeze

        STATUS_MAPPING = {
          '01d' => 'clear',
          '02d' => 'partly_cloudy',
          '03d' => 'cloudy',
          '04d' => 'cloudy',
          '09d' => 'rainy',
          '10d' => 'rainy',
          '11d' => 'stormy',
          '13d' => 'snowy',
          '50d' => 'foggy',
          '01n' => 'clear',
          '02n' => 'partly_cloudy',
          '03n' => 'cloudy',
          '04n' => 'cloudy',
          '09n' => 'rainy',
          '10n' => 'rainy',
          '11n' => 'stormy',
          '13n' => 'snowy',
          '50n' => 'foggy'
        }.freeze

        # Initializes the OpenweatherForecast.
        # @param request_handler [RequestHandler] the request handler for making requests.
        def initialize(request_handler)
          @request_handler = request_handler
          @api_key = ENV['OPENWEATHER_API_KEY']
        end
      end
    end
  end
end
