module Geo
  # Represents a standardized address object with attributes such as
  # name, address, latitude, longitude, country, city, and postcode.
  Address = Struct.new(:name, :address, :latitude, :longitude, :country, :city, :postcode, keyword_init: true) do
    def initialize(name: nil, address: nil, latitude: nil, longitude: nil, country: nil, city: nil, postcode: nil)
      super
    end
  end
end
