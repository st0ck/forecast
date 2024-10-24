module Meteo
  class Forecast < Array
    def initialize(forecast = [])
      super(forecast)
    end

    # Creates a new Forecast from an array of weather data.
    # @param data [Array<Hash>] an array of hashes containing weather data for multiple days.
    # @return [Meteo::Forecast] a new forecast object with daily weather information.
    # @raise [ArgumentError] if the input data is not an array.
    def self.from_data(data)
      raise ArgumentError, I18n.t('meteo.forecast.type_mismatch') unless data.is_a?(Array)

      forecast = data.map { |record| Meteo::Weather.from_data(record) }
      new(forecast)
    end
  end
end
