module Meteo
  # Represents a standardized weather data object with attributes such as temperature, feels_like, weather status, etc.
  Weather = Struct.new(
    :temperature, :feels_like, :status, :humidity, :wind_speed, :date, :max_temp, :min_temp,
    keyword_init: true
  ) do
    # Creates a new Meteo::Weather object from a hash of weather data.
    # @param data [Hash] a hash of weather data (keys must be symbols).
    # @return [Meteo::Weather] a new weather object.
    # @raise [ArgumentError] if the input data is not a hash.
    def self.from_data(data)
      raise ArgumentError, I18n.t('meteo.weather.type_mismatch') unless data.is_a?(Hash)

      Meteo::Weather.new(data.symbolize_keys)
    end
  end
end
