require 'test_helper'

class Geo::AddressListTest < ActiveSupport::TestCase
  def setup
    @valid_data = [
      {
        name: 'Googleplex',
        address: '1600 Amphitheatre Parkway, Mountain View, CA',
        latitude: 37.4220,
        longitude: -122.0841,
        country: 'United States',
        city: 'Mountain View',
        postcode: '94043'
      },
      {
        name: 'Apple Park',
        address: 'One Apple Park Way, Cupertino, CA',
        latitude: 37.3349,
        longitude: -122.0090,
        country: 'United States',
        city: 'Cupertino',
        postcode: '95014'
      }
    ]
  end

  test 'from_data creates a list of addresses from valid data' do
    address_list = Geo::AddressList.from_data(@valid_data)
    assert_equal 2, address_list.size

    first_address = address_list.first
    assert_equal 'Googleplex', first_address.name
    assert_equal '1600 Amphitheatre Parkway, Mountain View, CA', first_address.address
    assert_equal 37.4220, first_address.latitude
    assert_equal -122.0841, first_address.longitude
    assert_equal 'United States', first_address.country
    assert_equal 'Mountain View', first_address.city
    assert_equal '94043', first_address.postcode
  end

  test 'from_data handles empty data' do
    address_list = Geo::AddressList.from_data([])
    assert_equal 0, address_list.size
  end

  test 'from_data handles invalid data' do
    assert_raises(ArgumentError, 'Expected an array of address data') do
      address_list = Geo::AddressList.from_data([{ invalid: 'data' }])
    end

    assert_raises(ArgumentError, 'Expected an array of address data') do
      address_list = Geo::AddressList.from_data(nil)
    end

    assert_raises(ArgumentError, 'Expected each record to be a hash') do
      address_list = Geo::AddressList.from_data([nil])
    end
  end
end
