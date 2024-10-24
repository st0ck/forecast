module Geo
  class AddressList < Array
    def initialize(addresses = [])
      super(addresses)
    end

    # Creates a new AddressList from an array of address data.
    # @param data [Array<Hash>] an array of hashes containing address data.
    # @return [Geo::AddressList] a new list of addresses.
    # @raise [ArgumentError] if the input data is not an array.
    def self.from_data(data)
      raise ArgumentError, I18n.t('geo.address_list.type_mismatch') unless data.is_a?(Array)

      addresses = data.map { |record| Geo::Address.from_data(record) }
      new(addresses)
    end
  end
end
