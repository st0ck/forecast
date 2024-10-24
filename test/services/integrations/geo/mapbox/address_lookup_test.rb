require 'test_helper'

class Integrations::Geo::Mapbox::AddressLookupTest < ActiveSupport::TestCase
  def setup
    @query = '123 Main St'
    @session_token = 'test_session'
    @request_handler = RequestHandler.new

    @mapbox_service = Integrations::Geo::Mapbox::AddressLookup.new(
      query: @query,
      session_token: @session_token,
      request_handler: @request_handler
    )
  end

  test 'should fetch address from Mapbox service' do
    response_body = {
      'features' => [
        {
          'text' => 'Milwaukee Ave',
          'place_name' => '825 Milwaukee Ave, Wheeling, Illinois 60090, United States',
          'geometry' => { 'coordinates' => [-87.910299, 42.144504] },
          'context' => [
            { 'id' => 'country.9053006287256050', 'text' => 'United States' },
            { 'id' => 'place.9902190947082220', 'text' => 'Wheeling' },
            { 'id' => 'postcode.9418633295906190', 'text' => '60090' }
          ]
        }
      ]
    }.to_json

    response = Struct.new(:body).new(response_body)

    @request_handler.stubs(:make_request).returns(response)
    results = @mapbox_service.fetch

    assert_equal 1, results.size
    result = results.first
    assert_equal 'Milwaukee Ave', result[:name]
    assert_equal '825 Milwaukee Ave, Wheeling, Illinois 60090, United States', result[:address]
    assert_equal 42.144504, result[:latitude]
    assert_equal -87.910299, result[:longitude]
    assert_equal 'United States', result[:country]
    assert_equal 'Wheeling', result[:city]
    assert_equal '60090', result[:postcode]
  end

  test 'should handle empty response from Mapbox service' do
    response_body = { 'features' => [] }.to_json
    response = Struct.new(:body).new(response_body)

    @request_handler.stubs(:make_request).returns(response)
    results = @mapbox_service.fetch
    assert_equal 0, results.size
  end

  test 'should handle invalid JSON response from Mapbox service' do
    response_body = 'invalid json'
    response = Struct.new(:body).new(response_body)

    @request_handler.stubs(:make_request).returns(response)
    assert_raises(JSON::ParserError) do
      @mapbox_service.fetch
    end
  end
end
