module Geo
  # Represents a standardized address object with attributes such as
  # name, address, latitude, longitude, country, city, and postcode.
  Address = Struct.new(:name, :address, :latitude, :longitude, :country, :city, :postcode, keyword_init: true) do
    # Creates a new Geo::Address object from a hash of address data.
    # @param data [Hash] a hash of address data (keys must be symbols).
    # @return [Geo::Address] a new address object.
    # @raise [ArgumentError] if the input data is not a hash.
    def self.from_data(data)
      raise ArgumentError, I18n.t('geo.address.type_mismatch') unless data.is_a?(Hash)

      Geo::Address.new(data.symbolize_keys)
    end
  end
end
